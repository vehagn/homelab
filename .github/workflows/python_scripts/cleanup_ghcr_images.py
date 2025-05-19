#!/usr/bin/env python3
"""
GitHub Container Registry Cleanup Script

This script cleans up old container images in GitHub Container Registry according to retention rules:
1. Always keep the latest multi-arch manifest and its referenced images
2. Keep at most N dated version sets with priority to newer images
3. Delete everything else
"""

import argparse
import os
import re
import sys
from datetime import datetime, timedelta
from typing import Dict, List, Set

import requests


# ANSI color codes for terminal output
class Colors:
  RED    = "\033[0;31m" # Errors
  GREEN  = "\033[0;32m" # Success
  YELLOW = "\033[0;33m" # DryRun
  BLUE   = "\033[0;34m" # Keep
  VIOLET = "\033[0;35m" # Numbers
  RESET  = "\033[0m"    # Others


def parse_args() -> argparse.Namespace:
  """Parse command line arguments."""
  parser = argparse.ArgumentParser(description="Clean up old GitHub Container Registry images")
  parser.add_argument("--image_repo_name", required=True, help="Name of the image repository")
  parser.add_argument("--keep_recent_count", type=int, default=3,
                     help="Number of recent image sets to keep")
  parser.add_argument("--delete_older_than_days", type=int, default=30,
                     help="Delete images older than this many days")
  parser.add_argument("--dry_run", action="store_true",
                     help="Run in dry-run mode (no actual deletions)")
  parser.add_argument("--repo_owner", required=True,
                     help="Repository owner (user or organization)")
  parser.add_argument("--token",
                     help="GitHub token (if not provided, uses GITHUB_TOKEN environment variable)")
  return parser.parse_args()


def create_github_session(token: str) -> requests.Session:
  """Create and configure a requests session for GitHub API."""
  print("Preparing GitHub API session...")
  session = requests.Session()
  session.headers.update({
    "Accept": "application/vnd.github+json",
    "Authorization": f"Bearer {token}",
    "X-GitHub-Api-Version": "2022-11-28",
    "User-Agent": "GitHub-Package-Cleanup-Script"
  })

  # Skip token verification in GitHub Actions environment
  if os.environ.get("GITHUB_ACTIONS", "").lower() == "true":
    print(f"{Colors.GREEN}Running in GitHub Actions, skipping token verification{Colors.RESET}")
    return session

  if token.startswith("ghp_") or token.startswith("github_pat_"):
    print(f"{Colors.GREEN}Detected likely PAT (Personal Access Token). Verifying via /user...{Colors.RESET}")
  else:
    print(f"{Colors.YELLOW}Token does not appear to be a PAT. Verification via /user may fail (403).{Colors.RESET}")

  # Test the connection by getting the authenticated user
  try:
    response = session.get("https://api.github.com/user")
    response.raise_for_status()
    user = response.json().get("login")
    print(f"{Colors.GREEN}Successfully authenticated as {user}{Colors.RESET}")
    return session
  except requests.RequestException as e:
    print(f"{Colors.RED}Failed to authenticate with GitHub API: {e}{Colors.RESET}")
    raise


def fetch_package_versions(session: requests.Session, owner: str, repo_name: str) -> List:
  """Fetch all package versions from GitHub Container Registry."""
  print(f"Fetching package versions for {repo_name} using GitHub API...")

  all_versions = []
  owner_type = "org"
  base_url = None
  page = 1
  per_page = 100  # Maximum allowed by GitHub API

  # Try organization endpoint first
  org_url = f"https://api.github.com/orgs/{owner}/packages/container/{repo_name}/versions"
  try:
    # First determine if we're dealing with an org or user
    response = session.get(org_url)
    if response.status_code == 404:
      base_url = f"https://api.github.com/users/{owner}/packages/container/{repo_name}/versions"
      print(f"Owner type detected as: user for {owner}")
      owner_type = "user"
    else:
      base_url = org_url
      print(f"Owner type detected as: organization for {owner}")

    # Now fetch all pages
    while True:
      url = f"{base_url}?per_page={per_page}&page={page}"
      print(f"Fetching page {page}...")
      response = session.get(url)
      response.raise_for_status()

      page_versions = response.json()
      if not page_versions:
        break  # No more versions to fetch

      all_versions.extend(page_versions)

      # Check if there's a next page
      if 'next' in response.links:
        page += 1
      else:
        break

    # Enhance version objects with additional info
    for version in all_versions:
      version_id = version.get("id")
      name = version.get("name", "unknown")
      metadata = version.get("metadata", {})
      tags = metadata.get("container", {}).get("tags", [])
      # Add formatted info to each version object
      version["formatted_info"] = f"ID: {version_id}, Name: {name}, Tags: {tags}"
      version["owner_type"] = owner_type

    print(f"{Colors.VIOLET}Found {len(all_versions)} package versions across {page} page(s){Colors.RESET}")
    return all_versions
  except requests.RequestException as e:
    print(f"{Colors.RED}Error fetching package versions: {e}{Colors.RESET}")
    print(f"{Colors.RED}Make sure the package exists and you have access.{Colors.RESET}")
    return []


def find_latest_tag_versions(versions: List) -> Set[int]:
  """Find versions with the 'latest' tag and architecture-specific tags."""
  keep_version_ids = set()

  print("Finding and marking the main :latest tag for preservation...")

  for version in versions:
    version_id = version.get("id")
    metadata = version.get("metadata", {})
    tags = metadata.get("container", {}).get("tags", [])
    formatted_info = version.get("formatted_info", f"ID: {version_id}, Name: unknown, Tags: {tags}")

    if "latest" in tags:
      print(f"{Colors.BLUE}KEEPING (main :latest multi-arch manifest tag): {formatted_info}{Colors.RESET}")
      keep_version_ids.add(version_id)

    # Also keep architecture-specific latest tags
    for tag in tags:
      if tag == "latest-amd64" or tag == "latest-arm64":
        print(f"{Colors.BLUE}KEEPING (architecture-specific latest tag): {formatted_info}{Colors.RESET}")
        keep_version_ids.add(version_id)
        break  # Only print once per version if it has multiple arch tags

  return keep_version_ids


def group_versions_by_base(versions: List, delete_older_than_days: int) -> tuple:
  """Group versions by their base version and identify recent ones."""
  print("Finding and sorting all date-tagged versioned images...")
  date_tag_pattern = re.compile(r"^latest-([0-9]{8}-[0-9]{6}-[a-f0-9]{7})-(amd64|arm64)$")

  # Dictionaries to track versions
  base_versions = {}          # Map of base version -> creation date
  base_version_to_ids = {}    # Map of base version -> list of version IDs
  recent_base_versions = {}   # Map of recent base version -> creation date

  # Calculate cutoff date
  cutoff_date = (datetime.now() - timedelta(days=delete_older_than_days)).strftime("%Y%m%d")

  # Group all versions by their base version (YYYYMMDD-HHMMSS-SHA)
  for version in versions:
    try:
      version_id = version.get("id")
      created_at = version.get("created_at", "")
      metadata = version.get("metadata", {})
      tags = metadata.get("container", {}).get("tags", [])

      for tag in tags:
        match = date_tag_pattern.match(tag)
        if match:
          base_version = match.group(1)  # YYYYMMDD-HHMMSS-SHA

          # Store base version with creation date
          if base_version not in base_versions or created_at > base_versions[base_version]:
            base_versions[base_version] = created_at

          # Store version ID in the base version group
          if base_version not in base_version_to_ids:
            base_version_to_ids[base_version] = []
          base_version_to_ids[base_version].append(version_id)

          # Check if this is a recent version
          date_part = base_version.split("-")[0]  # YYYYMMDD
          if date_part > cutoff_date:
            recent_base_versions[base_version] = created_at
    except Exception as e:
      print(f"{Colors.YELLOW}Warning: Error processing version {version.get('id')}: {e}{Colors.RESET}")
      continue

  print(f"{Colors.VIOLET}Found {len(base_versions)} total version sets, "
        f"{len(recent_base_versions)} from the last {delete_older_than_days} days.{Colors.RESET}")

  return base_versions, base_version_to_ids, recent_base_versions


def print_version_details(base_version: str, base_version_to_ids: Dict[str, List[int]],
                          version_lookup: Dict, color: str):
  """Print details for each version in a version set."""
  if base_version in base_version_to_ids:
    for version_id in base_version_to_ids[base_version]:
      if version_id in version_lookup:
        formatted_info = version_lookup[version_id].get("formatted_info")
        print(f"{color}  - {formatted_info}{Colors.RESET}")

def add_version_set_to_keep(
  base_version: str,
  message: str,
  versions_to_keep: List[str],
  base_version_to_ids: Dict[str, List[int]],
  version_lookup: Dict
) -> None:
  """Add a version set to the list of versions to keep and print details."""
  versions_to_keep.append(base_version)
  print(f"{Colors.BLUE}KEEPING {message}: {base_version}{Colors.RESET}")
  print_version_details(base_version, base_version_to_ids, version_lookup, Colors.BLUE)

def select_versions_to_keep(
  base_versions: Dict[str, str],
  base_version_to_ids: Dict[str, List[int]],
  recent_base_versions: Dict[str, str],
  keep_recent_count: int,
  delete_older_than_days: int,
  versions: List
) -> Set[int]:
  """Select which version sets to keep based on retention rules."""
  keep_version_ids = set()
  versions_to_keep = []

  # Create lookup for version information
  version_lookup = {v.get("id"): v for v in versions}

  # First prioritize recent versions
  recent_sorted = sorted(
    recent_base_versions.items(),
    key=lambda x: x[1],
    reverse=True  # newest first
  )

  # Keep the most recent ones up to keep_recent_count
  for base_version, created_at in recent_sorted:
    if len(versions_to_keep) < keep_recent_count:
      message = f"(recent version set within {delete_older_than_days} days)"
      add_version_set_to_keep(base_version, message, versions_to_keep, base_version_to_ids, version_lookup)

  # If we haven't reached keep_recent_count, add older versions
  if len(versions_to_keep) < keep_recent_count:
    all_sorted = sorted(
      base_versions.items(),
      key=lambda x: x[1],
      reverse=True  # newest first
    )

    for base_version, created_at in all_sorted:
      if base_version not in versions_to_keep and len(versions_to_keep) < keep_recent_count:
        message = f"(older version set to reach count of {keep_recent_count})"
        add_version_set_to_keep(base_version, message, versions_to_keep, base_version_to_ids, version_lookup)

  # Add all version IDs from the kept base versions to our keep set
  for base_version in versions_to_keep:
    if base_version in base_version_to_ids:
      for version_id in base_version_to_ids[base_version]:
        keep_version_ids.add(version_id)

  print(f"{Colors.VIOLET}Total kept version sets: {len(versions_to_keep)} (max allowed: {keep_recent_count}){Colors.RESET}")
  return keep_version_ids


def identify_versions_to_keep(versions: List, keep_recent_count: int, delete_older_than_days: int) -> Set[int]:
    """
    Identify which versions to keep based on retention rules.

    Returns a set of version IDs to keep.
    """
    # Step 1: Always keep the latest multi-arch manifest and its referenced images
    keep_version_ids = find_latest_tag_versions(versions)

    # Step 2: Identify and sort date-tagged architecture-specific images
    base_versions, base_version_to_ids, recent_base_versions = group_versions_by_base(
        versions, delete_older_than_days
    )

    # Step 3: Select which versions to keep based on retention policy
    version_ids_from_sets = select_versions_to_keep(
        base_versions, base_version_to_ids, recent_base_versions,
        keep_recent_count, delete_older_than_days, versions
    )

    # Combine all versions to keep
    keep_version_ids.update(version_ids_from_sets)

    return keep_version_ids


def identify_versions_to_delete(versions: List, keep_version_ids: Set[int]) -> List[int]:
    """Identify which versions to delete (those not in keep_version_ids)."""
    delete_version_ids = []

    print("Evaluating all versions against our retention criteria...")
    for version in versions:
        version_id = version.get("id")

        # Skip versions we've already decided to keep
        if version_id in keep_version_ids:
            continue

        delete_version_ids.append(version_id)

    return delete_version_ids


def delete_versions(
  session: requests.Session,
  owner: str,
  repo_name: str,
  versions: List,
  delete_version_ids: List[int],
  dry_run: bool
) -> int:
  """Delete specified versions and return the count of deleted versions."""
  deleted_count = 0

  if not delete_version_ids:
    print(f"{Colors.GREEN}No image versions to delete based on current criteria.{Colors.RESET}")
    return 0

  if dry_run:
    print(f"{Colors.YELLOW}DRY RUN ENABLED: The following deletions will not actually occur.{Colors.RESET}")

  print(f"{Colors.VIOLET}Proceeding to delete {len(delete_version_ids)} image version(s)...{Colors.RESET}")

  # Create version lookup
  version_lookup = {v.get("id"): v for v in versions}

  for version_id in delete_version_ids:
    version = version_lookup.get(version_id, {})
    formatted_info = version.get("formatted_info", f"ID: {version_id}, Name: unknown, Tags: []")

    if dry_run:
      print(f"{Colors.YELLOW}DRY RUN: Would delete package {formatted_info}{Colors.RESET}")
      deleted_count += 1
    else:
      print(f"Deleting package {formatted_info}...")
      try:
        endpoints = {
          "org": f"https://api.github.com/orgs/{owner}/packages/container/{repo_name}/versions/{version_id}",
          "user": f"https://api.github.com/users/{owner}/packages/container/{repo_name}/versions/{version_id}"
        }

        owner_type = version.get("owner_type", "org")  # Default to org if not specified
        endpoint = endpoints[owner_type]

        response = session.delete(endpoint)
        if response.status_code == 204:
          deleted_count += 1
          print(f"{Colors.GREEN}Successfully deleted {formatted_info}{Colors.RESET}")
        else:
          print(f"{Colors.RED}Failed to delete {formatted_info}: Received non-204 response{Colors.RESET}")

      except requests.RequestException as e:
        print(f"{Colors.RED}Failed to delete {formatted_info}: {e}{Colors.RESET}")
      except KeyError as e:
        print(f"{Colors.RED}Failed to delete {formatted_info}: Invalid owner type {e}{Colors.RESET}")

  print(f"{Colors.VIOLET}Deleted {deleted_count} image version(s).{Colors.RESET}")
  return deleted_count


def main() -> int:
  """Main entry point for the script."""
  args = parse_args()

  # Convert arguments to variables
  image_repo_name = args.image_repo_name
  keep_recent_count = args.keep_recent_count
  delete_older_than_days = args.delete_older_than_days
  dry_run = args.dry_run
  repo_owner = args.repo_owner.lower()  # Convert to lowercase for consistency

  print(f"Starting cleanup for {repo_owner}/{image_repo_name}...")
  print(f"Will prioritize keeping versions from the last {delete_older_than_days} days")
  print(f"Will keep at most {keep_recent_count} total dated version sets")

  try:
    # Get GitHub token from args or environment
    github_token = args.token or os.environ.get("GITHUB_TOKEN")
    if not github_token:
      print(f"{Colors.RED}Error: GitHub token not provided via --token and GITHUB_TOKEN environment variable not found{Colors.RESET}")
      return 1

    # Create authenticated session for GitHub API
    session = create_github_session(github_token)

    # Fetch all package versions from GitHub Container Registry
    versions = fetch_package_versions(session, repo_owner, image_repo_name)

    if not versions:
      print(f"{Colors.YELLOW}No package versions found for {image_repo_name}.{Colors.RESET}")
      print(f"{Colors.YELLOW}Nothing to clean up. Exiting.{Colors.RESET}")
      return 0

    print(f"{Colors.VIOLET}Found {len(versions)} package versions to process.{Colors.RESET}")

    # Identify which versions to keep
    keep_version_ids = identify_versions_to_keep(versions, keep_recent_count, delete_older_than_days)

    # Identify which versions to delete
    delete_version_ids = identify_versions_to_delete(versions, keep_version_ids)

    # Delete versions
    delete_versions(session, repo_owner, image_repo_name, versions, delete_version_ids, dry_run)

    print(f"Cleanup complete for {image_repo_name}.")
    return 0

  except Exception as e:
    print(f"{Colors.RED}An error occurred: {e}{Colors.RESET}")
    import traceback
    traceback.print_exc()
    return 1


if __name__ == "__main__":
    sys.exit(main())
