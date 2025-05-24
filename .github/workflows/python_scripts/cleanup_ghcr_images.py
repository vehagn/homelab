#!/usr/bin/env python3
"""
GitHub Container Registry Cleanup Script

This script cleans up old container images in GitHub Container Registry according to retention rules:
1. Always keep the latest multi-arch manifest and its referenced images
2. Keep at most N dated version sets with priority to newer images
3. Delete everything else

The script provides comprehensive error handling and classification to distinguish between
critical errors (that should fail the job) and minor errors (expected/recoverable).
"""

import argparse
import os
from enum import IntEnum
import re
import sys
import time
from datetime import datetime, timedelta
from typing import Dict, List, Set, Callable, Any, Tuple, Optional

import requests


class Colors:
  """ANSI color codes for terminal output formatting."""
  RED    = "\033[0;31m" # Errors
  GREEN  = "\033[0;32m" # Success
  YELLOW = "\033[0;33m" # DryRun
  BLUE   = "\033[0;34m" # Keep
  VIOLET = "\033[0;35m" # Numbers
  RESET  = "\033[0m"    # Others


class ErrorClassification:
  """
  Enhanced error classification system that matches the GitHub Actions workflow logic.

  This class determines whether errors are critical (should fail the job) or minor
  (expected/recoverable, should continue with warning).

  Attributes:
      CRITICAL_PATTERNS: List of regex patterns indicating critical errors
      MINOR_PATTERNS: List of regex patterns indicating minor/expected errors
      CRITICAL_STATUS_CODES: Set of HTTP status codes that are always critical
      MINOR_STATUS_CODES: Set of HTTP status codes that are always minor
  """

  # Critical error patterns that should cause job failure
  CRITICAL_PATTERNS = [
    r"authentication.*failed",
    r"unauthorized",
    r"forbidden",
    r"token.*invalid",
    r"token.*expired",
    r"permission.*denied",
    r"access.*denied",
    r"network.*error",
    r"connection.*failed",
    r"connection.*refused",
    r"connection.*timeout",
    r"timeout.*error",
    r"api.*error",
    r"api.*failure",
    r"rate.*limit.*exceeded",
    r"server.*error",
    r"internal.*server.*error",
    r"service.*unavailable",
    r"bad.*gateway",
    r"gateway.*timeout",
    r"dns.*resolution.*failed",
    r"ssl.*error",
    r"certificate.*error",
    r"proxy.*error"
  ]

  # Minor error patterns that are expected/recoverable
  MINOR_PATTERNS = [
    r"already.*deleted",
    r"not.*found",
    r"does.*not.*exist",
    r"no.*packages.*found",
    r"no.*versions.*found",
    r"404.*not.*found",
    r"resource.*not.*found",
    r"package.*not.*found",
    r"version.*not.*found",
    r"empty.*response",
    r"no.*data.*returned"
  ]

  # Status codes that are always critical
  CRITICAL_STATUS_CODES = {
    401,  # Unauthorized - auth issues
    403,  # Forbidden - permission issues
    429,  # Too Many Requests - rate limiting
    500, 502, 503, 504,  # Server errors
  }

  # Status codes that are always minor
  MINOR_STATUS_CODES = {
    404,  # Not Found - expected for missing resources
  }

  @classmethod
  def classify_error(cls, error_message: str, status_code: Optional[int] = None,
                    exception_type: Optional[str] = None) -> Tuple[bool, str]:
    """
    Comprehensive error classification that determines if an error is critical.

    Args:
        error_message: The error message to analyze
        status_code: Optional HTTP status code if available
        exception_type: Optional exception type name if available

    Returns:
        Tuple[bool, str]: A tuple containing:
            - bool: True if the error is critical, False if minor
            - str: Reason for the classification
    """
    error_lower = error_message.lower()

    # First check status codes for definitive classification
    if status_code is not None:
      if status_code in cls.CRITICAL_STATUS_CODES:
        return True, f"Critical HTTP status code: {status_code}"

      if status_code in cls.MINOR_STATUS_CODES:
        return False, f"Minor HTTP status code: {status_code}"

    # Check for critical patterns
    for pattern in cls.CRITICAL_PATTERNS:
      if re.search(pattern, error_lower, re.IGNORECASE):
        return True, f"Critical error pattern matched: {pattern}"

    # Check for minor patterns
    for pattern in cls.MINOR_PATTERNS:
      if re.search(pattern, error_lower, re.IGNORECASE):
        return False, f"Minor error pattern matched: {pattern}"

    # Exception type based classification
    if exception_type:
      critical_exceptions = [
        'ConnectionError', 'Timeout', 'SSLError', 'ProxyError',
        'TooManyRedirects', 'ConnectTimeout', 'ReadTimeout'
      ]
      if any(exc_type in exception_type for exc_type in critical_exceptions):
        return True, f"Critical exception type: {exception_type}"

    # Additional heuristics
    if any(keyword in error_lower for keyword in ['fatal', 'critical', 'severe']):
      return True, "Error message contains critical keywords"

    # Default to critical for safety, but with lower confidence
    return True, "Unknown error - defaulting to critical for safety"

  @classmethod
  def is_critical_error(cls, error_message: str, status_code: Optional[int] = None) -> bool:
    """
    Backward compatibility method for error classification.

    Args:
        error_message: The error message to analyze
        status_code: Optional HTTP status code if available

    Returns:
        bool: True if the error is critical, False if minor
    """
    is_critical, _ = cls.classify_error(error_message, status_code)
    return is_critical


class ScriptExit(IntEnum):
  """
  Comprehensive set of exit codes used by the script to indicate different outcomes.

  Exit Code Categories:
  0-9: Success states
  10-19: Authentication/Permission errors
  20-29: Rate limiting errors
  30-39: API errors
  40-49: Configuration/Input errors
  50-59: Unexpected errors
  130: Script interruption

  Attributes:
      SUCCESS: Script completed successfully with no issues
      SUCCESS_WITH_WARNINGS: Script completed but with non-critical issues
      SUCCESS_NOTHING_TO_DO: Script completed successfully but no action was needed
      AUTH_ERROR: Authentication or permission error
      TOKEN_ERROR: Invalid or expired token
      RATE_LIMIT_ERROR: Rate limit exceeded and retries exhausted
      API_ERROR: Unexpected API error after retries
      API_TIMEOUT: API timeout after retries
      CONFIG_ERROR: Invalid arguments or configuration
      INVALID_REPO: Repository not found or invalid
      UNEXPECTED_ERROR: Unexpected error during execution
      INTERRUPTED: Script was interrupted by user
  """
  # Success states (0-9)
  SUCCESS = 0                  # Pure success
  SUCCESS_WITH_WARNINGS = 1    # Success but with non-critical issues
  SUCCESS_NOTHING_TO_DO = 2    # Success but no action needed

  # Authentication/Permission errors (10-19)
  AUTH_ERROR = 10             # Authentication or permission error
  TOKEN_ERROR = 11           # Invalid or expired token

  # Rate limiting errors (20-29)
  RATE_LIMIT_ERROR = 20      # Rate limit exceeded and retries exhausted

  # API errors (30-39)
  API_ERROR = 30             # Unexpected API error after retries
  API_TIMEOUT = 31          # API timeout after retries

  # Configuration/Input errors (40-49)
  CONFIG_ERROR = 40         # Invalid arguments or configuration
  INVALID_REPO = 41        # Repository not found or invalid

  # Unexpected errors (50-59)
  UNEXPECTED_ERROR = 50     # Unexpected error during execution

  # Special cases
  INTERRUPTED = 130        # Script interrupted by user

  @classmethod
  def is_success(cls, code: int) -> bool:
    """Check if an exit code represents a successful execution."""
    return 0 <= code <= 9

  @classmethod
  def is_critical(cls, code: int) -> bool:
    """Check if an exit code represents a critical error."""
    return code >= 10 and code != cls.INTERRUPTED


class RetryableError(Exception):
  """
  Custom exception for retryable errors.

  Attributes:
      message: Error message
      is_critical: Whether this is a critical error
      retry_after: Optional delay before retry in seconds
  """
  def __init__(self, message: str, is_critical: bool = True, retry_after: Optional[int] = None):
    """
    Initialize RetryableError.

    Args:
        message: Error message
        is_critical: Whether this is a critical error
        retry_after: Optional delay before retry in seconds
    """
    super().__init__(message)
    self.is_critical = is_critical
    self.retry_after = retry_after


def parse_args() -> argparse.Namespace:
  """
  Parse command line arguments.

  Returns:
      argparse.Namespace: Parsed command line arguments
  """
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
  parser.add_argument("--max_retries", type=int, default=3,
                     help="Maximum number of retries for API calls")
  parser.add_argument("--retry_delay", type=int, default=5,
                     help="Delay between retries in seconds")
  parser.add_argument("--fail_on_minor_errors", action="store_true",
                     help="Fail script even on minor errors (for strict mode)")
  return parser.parse_args()


def _handle_rate_limit_error(
  response: requests.Response,
  delay: int
) -> bool:
  """
  Handle rate limit errors from the GitHub API.

  Args:
      response: The response object from the API call
      delay: Minimum delay in seconds between retries

  Returns:
      bool: True if rate limit was handled, False otherwise

  Raises:
      RetryableError: If rate limit reset time parsing fails
  """
  if response.status_code != 429:
    return False

  reset_time = response.headers.get('X-RateLimit-Reset')
  if reset_time:
    try:
      wait_time = max(int(reset_time) - int(time.time()), delay)
      print(f"{Colors.YELLOW}Rate limited. Waiting {wait_time} seconds...{Colors.RESET}")
      time.sleep(wait_time)
      return True
    except (ValueError, TypeError) as e:
      is_critical, reason = ErrorClassification.classify_error(
        str(e),
        status_code=response.status_code,
        exception_type=type(e).__name__
      )
      if is_critical:
        raise RetryableError(f"Failed to parse rate limit reset time: {e}", is_critical=True)
      return False
  return False


def _handle_server_error(
  response: requests.Response,
  attempt: int,
  max_retries: int,
  delay: int
) -> bool:
  """
  Handle server errors from the GitHub API.

  Args:
      response: The response object from the API call
      attempt: Current retry attempt number
      max_retries: Maximum number of retry attempts
      delay: Base delay in seconds between retries

  Returns:
      bool: True if server error was handled, False otherwise
  """
  error_msg = f"Server error: {response.text}"
  is_critical, reason = ErrorClassification.classify_error(
    error_msg,
    status_code=response.status_code
  )

  if not is_critical:
    return False

  wait_time = delay * (2 ** attempt)
  print(f"{Colors.YELLOW}Server error (attempt {attempt + 1}/{max_retries}). {reason}. Waiting {wait_time} seconds...{Colors.RESET}")
  time.sleep(wait_time)
  return True


def _should_retry_request_error(
  e: requests.exceptions.RequestException,
  attempt: int,
  max_retries: int,
  delay: int
) -> bool:
  """
  Determine if a request error should be retried.

  Args:
      e: The request exception that occurred
      attempt: Current retry attempt number
      max_retries: Maximum number of retry attempts
      delay: Base delay in seconds between retries

  Returns:
      bool: True if the error should be retried, False otherwise
  """
  if attempt == max_retries - 1:
    return False

  error_msg = str(e)
  # Type narrowing for response attribute
  response = e.response if hasattr(e, 'response') else None
  status_code = response.status_code if response is not None else None
  
  is_critical, reason = ErrorClassification.classify_error(
    error_msg,
    status_code=status_code,
    exception_type=type(e).__name__
  )

  if response is not None:
    if _handle_rate_limit_error(response, delay):
      return True
    elif _handle_server_error(response, attempt, max_retries, delay):
      return True
    elif not is_critical:
      return False

  # Network error or critical error - retry with backoff
  wait_time = delay * (2 ** attempt)
  print(f"{Colors.YELLOW}{reason} (attempt {attempt + 1}/{max_retries}). Waiting {wait_time} seconds...{Colors.RESET}")
  time.sleep(wait_time)
  return True


def retry_api_call(
  func: Callable[..., requests.Response],
  max_retries: int,
  delay: int,
  *args: Any,
  **kwargs: Any
) -> requests.Response:
  """
  Retry an API call with exponential backoff.

  Args:
      func: The function to retry
      max_retries: Maximum number of retry attempts
      delay: Base delay in seconds between retries
      *args: Positional arguments to pass to the function
      **kwargs: Keyword arguments to pass to the function

  Returns:
      requests.Response: The response from the successful API call

  Raises:
      requests.exceptions.RequestException: If all retries fail
  """
  for attempt in range(max_retries):
    try:
      return func(*args, **kwargs)
    except requests.exceptions.RequestException as e:
      if not _should_retry_request_error(e, attempt, max_retries, delay):
        raise e

  # This should never be reached due to the raise in the loop, but satisfies type checker
  raise RuntimeError("Max retries exceeded")


def create_github_session(token: str) -> requests.Session:
  """
  Create and configure a requests session for GitHub API.

  Args:
      token: GitHub authentication token

  Returns:
      requests.Session: Configured session for GitHub API calls

  Raises:
      requests.RequestException: If authentication fails
  """
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
    def verify_auth() -> requests.Response:
      response = session.get("https://api.github.com/user")
      response.raise_for_status()
      return response

    response = retry_api_call(verify_auth, max_retries=3, delay=5)
    user_data = response.json()
    user = user_data.get("login") if isinstance(user_data, dict) else "unknown"
    print(f"{Colors.GREEN}Successfully authenticated as {user}{Colors.RESET}")
    return session
  except requests.RequestException as e:
    print(f"{Colors.RED}Failed to authenticate with GitHub API: {e}{Colors.RESET}")
    raise


def _determine_owner_type(
  session: requests.Session,
  owner: str,
  repo_name: str,
  max_retries: int,
  delay: int
) -> Tuple[str, str]:
  """
  Determine if owner is org or user and return owner_type and base_url.

  Args:
      session: Authenticated GitHub API session
      owner: Repository owner name
      repo_name: Name of the image repository
      max_retries: Maximum number of retry attempts
      delay: Base delay in seconds between retries

  Returns:
      Tuple[str, str]: Tuple containing (owner_type, base_url)
  """
  org_url = f"https://api.github.com/orgs/{owner}/packages/container/{repo_name}/versions"

  def check_owner_type() -> requests.Response:
    response = session.get(org_url)
    return response

  response = retry_api_call(check_owner_type, max_retries, delay)
  if response.status_code == 404:
    base_url = f"https://api.github.com/users/{owner}/packages/container/{repo_name}/versions"
    print(f"Owner type detected as: user for {owner}")
    return "user", base_url
  else:
    print(f"Owner type detected as: organization for {owner}")
    return "org", org_url


def _fetch_single_page(
  session: requests.Session,
  url: str,
  page: int,
  max_retries: int,
  delay: int
) -> Tuple[List[Dict[str, Any]], bool]:
  """
  Fetch a single page of versions.

  Args:
      session: Authenticated GitHub API session
      url: API URL to fetch
      page: Page number being fetched
      max_retries: Maximum number of retry attempts
      delay: Base delay in seconds between retries

  Returns:
      Tuple[List[Dict[str, Any]], bool]: Tuple containing:
          - List of version objects from the page
          - Boolean indicating if there's a next page
  """
  print(f"Fetching page {page}...")

  def fetch_page() -> requests.Response:
    response = session.get(url)
    response.raise_for_status()
    return response

  try:
    response = retry_api_call(fetch_page, max_retries, delay)
    page_versions_data = response.json()

    # Ensure we have a list
    page_versions = page_versions_data if isinstance(page_versions_data, list) else []

    # Check if there's a next page
    has_next = bool(hasattr(response, 'links') and response.links and 'next' in response.links)

    return page_versions, has_next
  except requests.RequestException as e:
    print(f"{Colors.YELLOW}Warning: Failed to fetch page {page}: {e}{Colors.RESET}")
    return [], False


def _enhance_versions_with_metadata(
  versions: List[Dict[str, Any]],
  owner_type: str
) -> None:
  """
  Add formatted info and owner type to version objects.

  Args:
      versions: List of version objects to enhance
      owner_type: Type of owner (user or organization)
  """
  for version in versions:
    version_id = version.get("id")
    name = version.get("name", "unknown")
    metadata = version.get("metadata", {})
    tags = metadata.get("container", {}).get("tags", []) if isinstance(metadata, dict) else []
    # Add formatted info to each version object
    version["formatted_info"] = f"ID: {version_id}, Name: {name}, Tags: {tags}"
    version["owner_type"] = owner_type


def fetch_package_versions(
  session: requests.Session,
  owner: str,
  repo_name: str,
  max_retries: int,
  delay: int
) -> List[Dict[str, Any]]:
  """
  Fetch all package versions from GitHub Container Registry.

  Args:
      session: Authenticated GitHub API session
      owner: Repository owner (user or organization)
      repo_name: Name of the image repository
      max_retries: Maximum number of retry attempts
      delay: Base delay in seconds between retries

  Returns:
      List[Dict[str, Any]]: List of package version objects

  Raises:
      requests.RequestException: If API calls fail after retries
  """
  print(f"Fetching package versions for {repo_name} using GitHub API...")

  try:
    # Determine owner type and base URL
    owner_type, base_url = _determine_owner_type(session, owner, repo_name, max_retries, delay)

    # Fetch all pages
    all_versions: List[Dict[str, Any]] = []
    page = 1
    per_page = 100  # Maximum allowed by GitHub API
    consecutive_empty_pages = 0
    max_empty_pages = 3  # Stop if we get too many empty pages in a row

    while consecutive_empty_pages < max_empty_pages:
      url = f"{base_url}?per_page={per_page}&page={page}"
      page_versions, has_next = _fetch_single_page(session, url, page, max_retries, delay)

      if not page_versions:
        consecutive_empty_pages += 1
        if consecutive_empty_pages == 1:
          print(f"Page {page} is empty, checking {max_empty_pages - 1} more pages...")
        page += 1
        continue

      consecutive_empty_pages = 0  # Reset counter
      all_versions.extend(page_versions)

      if has_next:
        page += 1
      else:
        break

    # Enhance version objects with additional info
    _enhance_versions_with_metadata(all_versions, owner_type)

    print(f"{Colors.VIOLET}Found {len(all_versions)} package versions across {page} page(s){Colors.RESET}")
    return all_versions

  except requests.RequestException as e:
    print(f"{Colors.RED}Error fetching package versions: {e}{Colors.RESET}")
    print(f"{Colors.RED}Make sure the package exists and you have access.{Colors.RESET}")
    # Don't return empty list immediately - maybe there are no packages yet
    if "404" in str(e) or "Not Found" in str(e):
      print(f"{Colors.YELLOW}Package {repo_name} may not exist yet. This is normal for new repositories.{Colors.RESET}")
    return []


def find_latest_tag_versions(
  versions: List[Dict[str, Any]]
) -> Set[int]:
  """
  Find versions with the 'latest' tag and architecture-specific tags.

  Args:
      versions: List of version objects to search

  Returns:
      Set[int]: Set of version IDs to keep
  """
  keep_version_ids: Set[int] = set()

  print("Finding and marking the main :latest tag for preservation...")

  for version in versions:
    version_id = version.get("id")
    metadata = version.get("metadata", {})
    tags = metadata.get("container", {}).get("tags", []) if isinstance(metadata, dict) else []
    formatted_info = version.get("formatted_info", f"ID: {version_id}, Name: unknown, Tags: {tags}")

    if "latest" in tags:
      print(f"{Colors.BLUE}KEEPING (main :latest multi-arch manifest tag): {formatted_info}{Colors.RESET}")
      if isinstance(version_id, int):
        keep_version_ids.add(version_id)

    # Also keep architecture-specific latest tags
    for tag in tags:
      if tag == "latest-amd64" or tag == "latest-arm64":
        print(f"{Colors.BLUE}KEEPING (architecture-specific latest tag): {formatted_info}{Colors.RESET}")
        if isinstance(version_id, int):
          keep_version_ids.add(version_id)
        break  # Only print once per version if it has multiple arch tags

  return keep_version_ids


def group_versions_by_base(
  versions: List[Dict[str, Any]],
  delete_older_than_days: int
) -> Tuple[Dict[str, str], Dict[str, List[int]], Dict[str, str]]:
  """
  Group versions by their base version and identify recent ones.

  Args:
      versions: List of version objects to group
      delete_older_than_days: Number of days to consider a version recent

  Returns:
      Tuple[Dict[str, str], Dict[str, List[int]], Dict[str, str]]: Tuple containing:
          - Map of base version -> creation date
          - Map of base version -> list of version IDs
          - Map of recent base version -> creation date
  """
  print("Finding and sorting all date-tagged versioned images...")
  date_tag_pattern = re.compile(r"^latest-([0-9]{8}-[0-9]{6}-[a-f0-9]{7})-(amd64|arm64)$")

  # Dictionaries to track versions
  base_versions: Dict[str, str] = {}          # Map of base version -> creation date
  base_version_to_ids: Dict[str, List[int]] = {}    # Map of base version -> list of version IDs
  recent_base_versions: Dict[str, str] = {}   # Map of recent base version -> creation date

  # Calculate cutoff date
  try:
    cutoff_date = (datetime.now() - timedelta(days=delete_older_than_days)).strftime("%Y%m%d")
  except (ValueError, OverflowError) as e:
    print(f"{Colors.YELLOW}Warning: Invalid date calculation: {e}. Using 30 days as fallback.{Colors.RESET}")
    cutoff_date = (datetime.now() - timedelta(days=30)).strftime("%Y%m%d")

  # Group all versions by their base version (YYYYMMDD-HHMMSS-SHA)
  for version in versions:
    try:
      version_id = version.get("id")
      created_at = version.get("created_at", "")
      metadata = version.get("metadata", {})
      tags = metadata.get("container", {}).get("tags", []) if isinstance(metadata, dict) else []

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
          if isinstance(version_id, int):
            base_version_to_ids[base_version].append(version_id)

          # Check if this is a recent version
          try:
            date_part = base_version.split("-")[0]  # YYYYMMDD
            if date_part > cutoff_date:
              recent_base_versions[base_version] = created_at
          except (IndexError, ValueError) as e:
            print(f"{Colors.YELLOW}Warning: Could not parse date from version {base_version}: {e}{Colors.RESET}")
            continue
    except Exception as e:
      print(f"{Colors.YELLOW}Warning: Error processing version {version.get('id')}: {e}{Colors.RESET}")
      continue

  print(f"{Colors.VIOLET}Found {len(base_versions)} total version sets, "
        f"{len(recent_base_versions)} from the last {delete_older_than_days} days.{Colors.RESET}")

  return base_versions, base_version_to_ids, recent_base_versions


def print_version_details(
  base_version: str,
  base_version_to_ids: Dict[str, List[int]],
  version_lookup: Dict[int, Dict[str, Any]],
  color: str
) -> None:
  """
  Print details for each version in a version set.

  Args:
      base_version: Base version identifier
      base_version_to_ids: Map of base version to list of version IDs
      version_lookup: Map of version ID to version object
      color: ANSI color code to use for output
  """
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
  version_lookup: Dict[int, Dict[str, Any]]
) -> None:
  """
  Add a version set to the list of versions to keep and print details.

  Args:
      base_version: Base version identifier
      message: Message explaining why this version set is being kept
      versions_to_keep: List of base versions to keep
      base_version_to_ids: Map of base version to list of version IDs
      version_lookup: Map of version ID to version object
  """
  versions_to_keep.append(base_version)
  print(f"{Colors.BLUE}KEEPING {message}: {base_version}{Colors.RESET}")
  print_version_details(base_version, base_version_to_ids, version_lookup, Colors.BLUE)


def _get_sorted_versions(
  version_dict: Dict[str, str]
) -> List[Tuple[str, str]]:
  """
  Sort versions by creation date, newest first.

  Args:
      version_dict: Map of version identifier to creation date

  Returns:
      List[Tuple[str, str]]: List of (version, creation_date) tuples, sorted by date
  """
  try:
    return sorted(version_dict.items(), key=lambda x: x[1], reverse=True)
  except (TypeError, ValueError) as e:
    print(f"{Colors.YELLOW}Warning: Could not sort versions: {e}. Using unsorted list.{Colors.RESET}")
    return list(version_dict.items())


def _add_recent_versions(
  recent_base_versions: Dict[str, str],
  keep_recent_count: int,
  delete_older_than_days: int,
  versions_to_keep: List[str],
  base_version_to_ids: Dict[str, List[int]],
  version_lookup: Dict[int, Dict[str, Any]]
) -> None:
  """
  Add recent versions to the keep list.

  Args:
      recent_base_versions: Map of recent base version to creation date
      keep_recent_count: Maximum number of version sets to keep
      delete_older_than_days: Number of days to consider a version recent
      versions_to_keep: List of base versions to keep
      base_version_to_ids: Map of base version to list of version IDs
      version_lookup: Map of version ID to version object
  """
  recent_sorted = _get_sorted_versions(recent_base_versions)

  for base_version, _ in recent_sorted:
    if len(versions_to_keep) >= keep_recent_count:
      break
    message = f"(recent version set within {delete_older_than_days} days)"
    add_version_set_to_keep(base_version, message, versions_to_keep, base_version_to_ids, version_lookup)


def _add_older_versions_if_needed(
  base_versions: Dict[str, str],
  keep_recent_count: int,
  versions_to_keep: List[str],
  base_version_to_ids: Dict[str, List[int]],
  version_lookup: Dict[int, Dict[str, Any]]
) -> None:
  """
  Add older versions if we haven't reached the keep_recent_count.

  Args:
      base_versions: Map of base version to creation date
      keep_recent_count: Maximum number of version sets to keep
      versions_to_keep: List of base versions to keep
      base_version_to_ids: Map of base version to list of version IDs
      version_lookup: Map of version ID to version object
  """
  if len(versions_to_keep) >= keep_recent_count:
    return

  all_sorted = _get_sorted_versions(base_versions)

  for base_version, _ in all_sorted:
    if len(versions_to_keep) >= keep_recent_count:
      break
    if base_version not in versions_to_keep:
      message = f"(older version set to reach count of {keep_recent_count})"
      add_version_set_to_keep(base_version, message, versions_to_keep, base_version_to_ids, version_lookup)


def _collect_version_ids_to_keep(
  versions_to_keep: List[str],
  base_version_to_ids: Dict[str, List[int]]
) -> Set[int]:
  """
  Collect all version IDs from the kept base versions.

  Args:
      versions_to_keep: List of base versions to keep
      base_version_to_ids: Map of base version to list of version IDs

  Returns:
      Set[int]: Set of version IDs to keep
  """
  keep_version_ids: Set[int] = set()
  for base_version in versions_to_keep:
    if base_version in base_version_to_ids:
      for version_id in base_version_to_ids[base_version]:
        keep_version_ids.add(version_id)
  return keep_version_ids


def select_versions_to_keep(
  base_versions: Dict[str, str],
  base_version_to_ids: Dict[str, List[int]],
  recent_base_versions: Dict[str, str],
  keep_recent_count: int,
  delete_older_than_days: int,
  versions: List[Dict[str, Any]]
) -> Set[int]:
  """
  Select which version sets to keep based on retention rules.

  Args:
      base_versions: Map of base version to creation date
      base_version_to_ids: Map of base version to list of version IDs
      recent_base_versions: Map of recent base version to creation date
      keep_recent_count: Maximum number of version sets to keep
      delete_older_than_days: Number of days to consider a version recent
      versions: List of all version objects

  Returns:
      Set[int]: Set of version IDs to keep
  """
  versions_to_keep: List[str] = []

  # Create lookup for version information
  version_lookup: Dict[int, Dict[str, Any]] = {}
  for v in versions:
    version_id = v.get("id")
    if isinstance(version_id, int):
      version_lookup[version_id] = v

  # Add recent versions first
  _add_recent_versions(
    recent_base_versions, keep_recent_count, delete_older_than_days,
    versions_to_keep, base_version_to_ids, version_lookup
  )

  # Add older versions if needed to reach keep_recent_count
  _add_older_versions_if_needed(
    base_versions, keep_recent_count, versions_to_keep,
    base_version_to_ids, version_lookup
  )

  # Collect all version IDs from the kept base versions
  keep_version_ids = _collect_version_ids_to_keep(versions_to_keep, base_version_to_ids)

  print(f"{Colors.VIOLET}Total kept version sets: {len(versions_to_keep)} (max allowed: {keep_recent_count}){Colors.RESET}")
  return keep_version_ids


def identify_versions_to_keep(
  versions: List[Dict[str, Any]],
  keep_recent_count: int,
  delete_older_than_days: int
) -> Set[int]:
  """
  Identify which versions to keep based on retention rules.

  Args:
      versions: List of all version objects
      keep_recent_count: Maximum number of version sets to keep
      delete_older_than_days: Number of days to consider a version recent

  Returns:
      Set[int]: Set of version IDs to keep
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


def identify_versions_to_delete(
  versions: List[Dict[str, Any]],
  keep_version_ids: Set[int]
) -> List[int]:
  """
  Identify which versions to delete (those not in keep_version_ids).

  Args:
      versions: List of all version objects
      keep_version_ids: Set of version IDs to keep

  Returns:
      List[int]: List of version IDs to delete
  """
  delete_version_ids: List[int] = []

  print("Evaluating all versions against our retention criteria...")
  for version in versions:
    version_id = version.get("id")

    # Skip versions we've already decided to keep
    if isinstance(version_id, int) and version_id in keep_version_ids:
      continue

    if isinstance(version_id, int):
      delete_version_ids.append(version_id)

  return delete_version_ids


def _attempt_version_deletion(
  session: requests.Session,
  endpoint: str,
  version_id: int,
  formatted_info: str,
  max_retries: int,
  delay: int
) -> bool:
  """
  Attempt to delete a single version.

  Args:
      session: Authenticated GitHub API session
      endpoint: API endpoint for deletion
      version_id: ID of the version to delete
      formatted_info: Formatted string with version details for logging
      max_retries: Maximum number of retry attempts
      delay: Base delay in seconds between retries

  Returns:
      bool: True if deletion was successful, False otherwise
  """
  def delete_version() -> requests.Response:
    response = session.delete(endpoint)
    if response.status_code == 204:
      return response
    elif response.status_code == 404:
      print(f"{Colors.YELLOW}Version {version_id} already deleted or not found{Colors.RESET}")
      return response
    else:
      response.raise_for_status()
      return response

  try:
    response = retry_api_call(delete_version, max_retries, delay)
    if response.status_code in [204, 404]:
      print(f"{Colors.GREEN}Successfully deleted {formatted_info}{Colors.RESET}")
      return True
  except requests.RequestException as e:
    print(f"{Colors.RED}Failed to delete {formatted_info}: {e}{Colors.RESET}")
  except Exception as e:
    print(f"{Colors.RED}Unexpected error deleting {formatted_info}: {e}{Colors.RESET}")

  return False


def _process_deletion_batch(
  session: requests.Session,
  owner: str,
  repo_name: str,
  batch: List[int],
  version_lookup: Dict[int, Dict[str, Any]],
  dry_run: bool,
  max_retries: int,
  delay: int
) -> int:
  """
  Process a batch of deletions.

  Args:
      session: Authenticated GitHub API session
      owner: Repository owner name
      repo_name: Name of the image repository
      batch: List of version IDs to delete
      version_lookup: Map of version ID to version object
      dry_run: Whether to run in dry-run mode (no actual deletions)
      max_retries: Maximum number of retry attempts
      delay: Base delay in seconds between retries

  Returns:
      int: Number of successfully deleted versions
  """
  deleted_count = 0

  endpoints = {
    "org": f"https://api.github.com/orgs/{owner}/packages/container/{repo_name}/versions/",
    "user": f"https://api.github.com/users/{owner}/packages/container/{repo_name}/versions/"
  }

  for version_id in batch:
    version = version_lookup.get(version_id, {})
    formatted_info = version.get("formatted_info", f"ID: {version_id}, Name: unknown, Tags: []")

    if dry_run:
      print(f"{Colors.YELLOW}DRY RUN: Would delete package {formatted_info}{Colors.RESET}")
      deleted_count += 1
      continue

    print(f"Deleting package {formatted_info}...")

    owner_type = version.get("owner_type", "org")  # Default to org if not specified
    if owner_type not in endpoints:
      print(f"{Colors.RED}Failed to delete {formatted_info}: Invalid owner type {owner_type}{Colors.RESET}")
      continue

    endpoint = endpoints[owner_type] + str(version_id)

    if _attempt_version_deletion(session, endpoint, version_id, formatted_info, max_retries, delay):
      deleted_count += 1

  return deleted_count


def delete_versions(
  session: requests.Session,
  owner: str,
  repo_name: str,
  versions: List[Dict[str, Any]],
  delete_version_ids: List[int],
  dry_run: bool,
  max_retries: int,
  delay: int
) -> int:
  """
  Delete specified versions and return the count of deleted versions.

  Args:
      session: Authenticated GitHub API session
      owner: Repository owner name
      repo_name: Name of the image repository
      versions: List of all version objects
      delete_version_ids: List of version IDs to delete
      dry_run: Whether to run in dry-run mode (no actual deletions)
      max_retries: Maximum number of retry attempts
      delay: Base delay in seconds between retries

  Returns:
      int: Number of successfully deleted versions
  """
  if not delete_version_ids:
    print(f"{Colors.GREEN}No image versions to delete based on current criteria.{Colors.RESET}")
    return 0

  if dry_run:
    print(f"{Colors.YELLOW}DRY RUN ENABLED: The following deletions will not actually occur.{Colors.RESET}")

  print(f"{Colors.VIOLET}Proceeding to delete {len(delete_version_ids)} image version(s)...{Colors.RESET}")

  # Create version lookup
  version_lookup: Dict[int, Dict[str, Any]] = {}
  for v in versions:
    version_id = v.get("id")
    if isinstance(version_id, int):
      version_lookup[version_id] = v

  # Delete in batches to avoid overwhelming the API
  batch_size = 5
  total_deleted = 0

  for i in range(0, len(delete_version_ids), batch_size):
    batch = delete_version_ids[i:i+batch_size]
    print(f"Processing deletion batch {i//batch_size + 1} ({len(batch)} items)...")

    batch_deleted = _process_deletion_batch(
      session, owner, repo_name, batch, version_lookup, dry_run, max_retries, delay
    )
    total_deleted += batch_deleted

    # Small delay between batches to be nice to the API
    if i + batch_size < len(delete_version_ids):
      time.sleep(2)

  print(f"{Colors.VIOLET}Deleted {total_deleted} image version(s).{Colors.RESET}")
  return total_deleted


def _setup_github_session(github_token: str) -> requests.Session:
  """
  Set up and verify GitHub API session.

  Args:
      github_token: GitHub authentication token

  Returns:
      requests.Session: Authenticated session for GitHub API

  Raises:
      requests.RequestException: If authentication fails
  """
  try:
    session = create_github_session(github_token)
    return session
  except requests.RequestException as e:
    if "401" in str(e) or "Unauthorized" in str(e):
      raise requests.RequestException("Token unauthorized") from e
    elif "403" in str(e) or "Forbidden" in str(e):
      raise requests.RequestException("Permission denied") from e
    else:
      raise

def _fetch_and_validate_versions(
  session: requests.Session,
  repo_owner: str,
  image_repo_name: str,
  max_retries: int,
  retry_delay: int
) -> List[Dict[str, Any]]:
  """
  Fetch and validate package versions.

  Args:
      session: Authenticated GitHub API session
      repo_owner: Repository owner name
      image_repo_name: Name of the image repository
      max_retries: Maximum number of retry attempts
      retry_delay: Base delay in seconds between retries

  Returns:
      List[Dict[str, Any]]: List of package version objects

  Raises:
      requests.RequestException: If API calls fail after retries
  """
  try:
    versions = fetch_package_versions(session, repo_owner, image_repo_name, max_retries, retry_delay)
    if not versions:
      print(f"{Colors.YELLOW}No package versions found for {image_repo_name}.{Colors.RESET}")
      print(f"{Colors.YELLOW}Nothing to clean up. Exiting.{Colors.RESET}")
      return []
    print(f"{Colors.VIOLET}Found {len(versions)} package versions to process.{Colors.RESET}")
    return versions
  except requests.RequestException as e:
    if "404" in str(e) or "Not Found" in str(e):
      raise requests.RequestException("Repository not found") from e
    elif "429" in str(e) or "rate limit" in str(e).lower():
      raise requests.RequestException("Rate limit exceeded") from e
    else:
      raise

def _process_version_cleanup(
  session: requests.Session,
  repo_owner: str,
  image_repo_name: str,
  versions: List[Dict[str, Any]],
  keep_recent_count: int,
  delete_older_than_days: int,
  dry_run: bool,
  max_retries: int,
  retry_delay: int
) -> int:
  """
  Process version cleanup including identifying and deleting versions.

  Args:
      session: Authenticated GitHub API session
      repo_owner: Repository owner name
      image_repo_name: Name of the image repository
      versions: List of version objects
      keep_recent_count: Maximum number of version sets to keep
      delete_older_than_days: Number of days to consider a version recent
      dry_run: Whether to run in dry-run mode
      max_retries: Maximum number of retry attempts
      retry_delay: Base delay in seconds between retries

  Returns:
      int: ScriptExit code indicating success or failure state
  """
  try:
    # Identify which versions to keep
    keep_version_ids = identify_versions_to_keep(versions, keep_recent_count, delete_older_than_days)

    # Identify which versions to delete
    delete_version_ids = identify_versions_to_delete(versions, keep_version_ids)

    # Delete versions
    deleted_count = delete_versions(session, repo_owner, image_repo_name, versions,
                                  delete_version_ids, dry_run, max_retries, retry_delay)
    print(f"{Colors.GREEN}Cleanup complete for {image_repo_name}.{Colors.RESET}")

    # Return appropriate success code based on what happened
    if deleted_count == 0 and not delete_version_ids:
      return ScriptExit.SUCCESS_NOTHING_TO_DO
    elif deleted_count < len(delete_version_ids):
      return ScriptExit.SUCCESS_WITH_WARNINGS
    else:
      return ScriptExit.SUCCESS

  except requests.RequestException as e:
    if "429" in str(e) or "rate limit" in str(e).lower():
      raise requests.RequestException("Rate limit exceeded") from e
    elif "timeout" in str(e).lower():
      raise requests.RequestException("API timeout") from e
    elif any(code in str(e) for code in ["401", "403"]):
      raise requests.RequestException("Authentication failed") from e
    else:
      raise

def _handle_request_exception(e: requests.RequestException) -> ScriptExit:
  """
  Handles known requests.RequestException types and returns an appropriate ScriptExit code.

  This function inspects the error message of the given exception to categorize it
  into specific error types like token issues, permission denied, repository not found,
  rate limits, or timeouts. It also prints a colored message to the console.

  Args:
      e: The requests.RequestException instance to handle.

  Returns:
      ScriptExit: The corresponding ScriptExit enum member based on the error analysis.
                  Returns ScriptExit.API_ERROR for unrecognized RequestExceptions.
  """
  error_msg = str(e)
  if "Token unauthorized" in error_msg:
    print(f"{Colors.RED}Error: GitHub token is unauthorized. {e}{Colors.RESET}")
    return ScriptExit.TOKEN_ERROR
  elif "Permission denied" in error_msg:
    print(f"{Colors.RED}Error: Permission denied. Check token scopes. {e}{Colors.RESET}")
    return ScriptExit.AUTH_ERROR
  elif "Repository not found" in error_msg:
    print(f"{Colors.RED}Error: Repository not found. {e}{Colors.RESET}")
    return ScriptExit.INVALID_REPO
  elif "Rate limit exceeded" in error_msg:
    print(f"{Colors.YELLOW}Warning: Rate limit exceeded. {e}{Colors.RESET}")
    return ScriptExit.RATE_LIMIT_ERROR
  elif "API timeout" in error_msg:
    print(f"{Colors.YELLOW}Warning: API call timed out. {e}{Colors.RESET}")
    return ScriptExit.API_TIMEOUT
  elif "Authentication failed" in error_msg: # General authentication failure
    print(f"{Colors.RED}Error: Authentication failed. {e}{Colors.RESET}")
    return ScriptExit.AUTH_ERROR
  else:
    print(f"{Colors.RED}An API error occurred: {e}{Colors.RESET}")
    return ScriptExit.API_ERROR

def _handle_retryable_error_exit_code(e: RetryableError) -> ScriptExit:
  """
  Determines the ScriptExit code after all retries for a RetryableError have failed.

  This function inspects the error message of the RetryableError to classify
  the persistent failure as a rate limit, timeout, or an authentication/permission
  issue. It prints a colored message to the console indicating the final failure reason.

  Args:
      e: The RetryableError instance that occurred after exhausting retries.

  Returns:
      ScriptExit: The corresponding ScriptExit enum member (e.g.,
                  ScriptExit.RATE_LIMIT_ERROR, ScriptExit.API_TIMEOUT,
                  ScriptExit.AUTH_ERROR). Returns ScriptExit.API_ERROR if the
                  error message doesn't match known retryable patterns.
  """
  error_str = str(e).lower()
  if "rate limit" in error_str:
    print(f"{Colors.YELLOW}Final attempt failed due to rate limiting: {e}{Colors.RESET}")
    return ScriptExit.RATE_LIMIT_ERROR
  elif "timeout" in error_str:
    print(f"{Colors.YELLOW}Final attempt failed due to API timeout: {e}{Colors.RESET}")
    return ScriptExit.API_TIMEOUT
  elif any(term in error_str for term in ["auth", "token", "permission"]):
    print(f"{Colors.RED}Final attempt failed due to an authentication/permission issue: {e}{Colors.RESET}")
    return ScriptExit.AUTH_ERROR
  else:
    print(f"{Colors.RED}Final attempt failed due to an API error after retries: {e}{Colors.RESET}")
    return ScriptExit.API_ERROR

def main() -> int:
  """
  Main entry point for the script.

  Returns:
      int: Exit code indicating specific success or failure state
  """
  try:
    args = parse_args()

    # Convert arguments to variables
    image_repo_name = args.image_repo_name
    keep_recent_count = args.keep_recent_count
    delete_older_than_days = args.delete_older_than_days
    dry_run = args.dry_run
    repo_owner = args.repo_owner.lower()
    max_retries = args.max_retries
    retry_delay = args.retry_delay

    print(f"Starting cleanup for {repo_owner}/{image_repo_name}...")
    print(f"Will prioritize keeping versions from the last {delete_older_than_days} days")
    print(f"Will keep at most {keep_recent_count} total dated version sets")
    print(f"Max retries per API call: {max_retries}")

    # Get GitHub token from args or environment
    github_token = args.token or os.environ.get("GITHUB_TOKEN")
    if not github_token:
      print(f"{Colors.RED}Error: GitHub token not provided via --token and GITHUB_TOKEN environment variable not found{Colors.RESET}")
      return ScriptExit.CONFIG_ERROR

    try:
      # Set up GitHub session
      session = _setup_github_session(github_token)

      # Fetch and validate versions
      versions = _fetch_and_validate_versions(session, repo_owner, image_repo_name, max_retries, retry_delay)
      if not versions:
        return ScriptExit.SUCCESS_NOTHING_TO_DO

      # Process version cleanup
      return _process_version_cleanup(
        session, repo_owner, image_repo_name, versions,
        keep_recent_count, delete_older_than_days,
        dry_run, max_retries, retry_delay
      )

    except requests.RequestException as e:
      return _handle_request_exception(e)

  except KeyboardInterrupt:
    print(f"\n{Colors.YELLOW}Cleanup interrupted by user.{Colors.RESET}")
    return ScriptExit.INTERRUPTED
  except RetryableError as e:
    return _handle_retryable_error_exit_code(e)
  except Exception as e:
    print(f"{Colors.RED}An unexpected error occurred: {e}{Colors.RESET}")
    import traceback
    traceback.print_exc()
    return ScriptExit.UNEXPECTED_ERROR


if __name__ == "__main__":
  sys.exit(main())
