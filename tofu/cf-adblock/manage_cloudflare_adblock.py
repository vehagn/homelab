#!/usr/bin/env python3

import os
import sys
import glob
import time
import hashlib
from cloudflare import Cloudflare
from cloudflare._exceptions import APIError, APIConnectionError, RateLimitError
import logging
import argparse
from typing import List, Dict, Optional, Any, Tuple, Literal

# --- Configuration ---
# These would ideally be fetched from environment variables or a config file
# For GitHub Actions, CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_API_TOKEN will be set as env vars
CLOUDFLARE_ACCOUNT_ID = os.environ.get("TF_VAR_cloudflare_secondary_account_id")
CLOUDFLARE_API_TOKEN = os.environ.get("TF_VAR_cloudflare_secondary_api_token")
# The DNS Location ID will be passed as an argument or fetched from Terraform output
# For now, let's assume it's passed as an environment variable by the GitHub Action
DNS_LOCATION_ID = os.environ.get("DNS_LOCATION_ID")

PROCESSED_CHUNKS_DIR = "./processed_adblock_chunks" # Relative to script execution
CHUNK_FILE_PATTERN = "adblock_chunk_*.txt"
LIST_NAME_PREFIX = "ad-block-list-" # To identify lists managed by this script
POLICY_NAME = "Block Ads - Managed by Script"
POLICY_DESCRIPTION = "Blocks ad domains using lists generated from external sources. Managed by Python script."

# ANSI color codes for terminal output
class Colors:
  RED    = "\033[0;31m" # Errors
  GREEN  = "\033[0;32m" # Success
  YELLOW = "\033[0;33m" # Warnings
  RESET  = "\033[0m"    # Others

# --- Logging Setup ---
# Formatter to add colors to log levels
class ColoredFormatter(logging.Formatter):
  def __init__(self, fmt: Optional[str] = None, datefmt: Optional[str] = None, style: Literal['%', '{', '$'] = '%', validate: bool = True):
    super().__init__(fmt, datefmt, style, validate=validate)
    self.level_colors = {
      logging.ERROR: Colors.RED,
      logging.WARNING: Colors.YELLOW,
      # INFO and DEBUG will use default terminal color (via RESET)
    }

  def format(self, record):
    log_message = super().format(record)
    log_level_color = self.level_colors.get(record.levelno, Colors.RESET)

    # For INFO and DEBUG, log_level_color will be Colors.RESET,
    # effectively not prepending a specific color for these levels,
    # but ensuring a reset if the previous line was colored.
    # If it's ERROR or WARNING, it will use the specified color.
    # We always append RESET to ensure color doesn't bleed.
    if record.levelno in (logging.ERROR, logging.WARNING):
        return f"{log_level_color}{log_message}{Colors.RESET}"
    return f"{log_message}{Colors.RESET}"

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Apply the colored formatter
if logger.hasHandlers():
  for handler in logger.handlers:
    original_formatter = handler.formatter
    fmt = original_formatter._fmt if original_formatter else '%(asctime)s - %(levelname)s - %(message)s'
    datefmt = original_formatter.datefmt if original_formatter else None
    colored_formatter = ColoredFormatter(fmt=fmt, datefmt=datefmt)
    handler.setFormatter(colored_formatter)
elif logging.root.hasHandlers():
    for handler in logging.root.handlers:
        original_formatter = handler.formatter
        fmt = original_formatter._fmt if original_formatter else '%(asctime)s - %(levelname)s - %(message)s'
        datefmt = original_formatter.datefmt if original_formatter else None
        colored_formatter = ColoredFormatter(fmt=fmt, datefmt=datefmt)
        handler.setFormatter(colored_formatter)


# --- Hash-based Change Detection ---
def calculate_list_hash(items: List[str]) -> str:
  """Calculate SHA-256 hash of sorted list items for change detection."""
  # Sort items to ensure consistent hash regardless of order
  sorted_items = sorted(set(items))  # Also removes duplicates
  content = '\n'.join(sorted_items).encode('utf-8')
  return hashlib.sha256(content).hexdigest()[:16]  # Use first 16 chars for brevity

def get_list_description_with_hash(base_description: str, items_hash: str) -> str:
  """Embed hash in description for change detection."""
  return f"{base_description} [Hash: {items_hash}]"

def extract_hash_from_description(description: str) -> Optional[str]:
  """Extract hash from list description if present."""
  if "[Hash: " in description and "]" in description:
    start = description.find("[Hash: ") + 7
    end = description.find("]", start)
    if start > 6 and end > start:
      return description[start:end]
  return None

def has_list_changed(current_items: List[str], existing_description: str) -> bool:
  """Check if list has changed by comparing hashes."""
  current_hash = calculate_list_hash(current_items)
  existing_hash = extract_hash_from_description(existing_description)

  if existing_hash is None:
    logger.info("No hash found in existing description, assuming change needed.")
    return True

  changed = current_hash != existing_hash
  logger.debug(f"Hash comparison - Current: {current_hash}, Existing: {existing_hash}, Changed: {changed}")
  return changed

# --- Cloudflare API Client Wrapper ---
class CloudflareManager:
  def __init__(self, account_id: str, api_token: str):
    if not account_id or not api_token:
      logger.error("Cloudflare Account ID and API Token must be provided.")
      raise ValueError("Cloudflare Account ID and API Token must be provided.")
    self.account_id = account_id
    self.cf = Cloudflare(api_token=api_token)
    logger.info("Cloudflare client initialized.")

  def _api_call_with_retry(self, method_func, *args, **kwargs) -> Any:
    # Cloudflare specific retry logic
    delays = [2, 5, 30, 30, 60]
    # 'retries' now represents the number of times we will retry after the initial attempt.
    # This means there will be (retries + 1) total attempts.
    retries = len(delays)
    for i in range(retries + 1):
      try:
        return method_func(*args, **kwargs)
      except (RateLimitError, APIConnectionError) as e:
        # Handle both rate limits and connection errors with the same retry logic
        error_type = "Rate limit" if isinstance(e, RateLimitError) else "Connection error"
        logger.warning(f"{error_type}: {e}")
        if i < retries:
          delay = delays[i]
          logger.warning(f"Retrying in {delay}s... (Attempt {i+1}/{retries})")
          time.sleep(delay)
        else:
          logger.error(f"Failed after {retries} attempts due to {error_type.lower()}")
          raise
      except APIError as e:
        # Handle various API errors
        error_msg = str(e).lower()
        if "not found" in error_msg or "404" in error_msg:
          logger.warning(f"Resource not found: {e}. This might be expected for GET operations.")
          return None
        elif "already exists" in error_msg or "409" in error_msg:
          logger.warning(f"Resource already exists: {e}")
          raise  # Re-raise to handle in context
        else:
          logger.error(f"Cloudflare API Error: {e}")
          raise  # Re-raise other API errors
      except Exception as e:
        logger.error(f"An unexpected error occurred during API call: {e}")
        if i < retries:
          delay = delays[i]
          logger.warning(f"Retrying in {delay}s... (Attempt {i+1}/{retries})")
          time.sleep(delay)
        else:
          raise
    raise Exception(f"API call failed after {retries} retries.")

  def get_all_zt_lists_by_prefix(self, prefix: str) -> Dict[str, Dict[str, Any]]:
    logger.info(f"Fetching all Zero Trust lists with prefix {prefix}...")

    def _get_lists():
      return self.cf.zero_trust.gateway.lists.list(account_id=self.account_id)

    lists_response = self._api_call_with_retry(_get_lists)

    script_lists = {}
    if lists_response:
      for lst in lists_response:
        if lst.name.startswith(prefix):
          script_lists[lst.name] = {
            'id': lst.id,
            'count': getattr(lst, 'count', 0),
            'description': getattr(lst, 'description', '')
          }
    logger.info(f"Found {len(script_lists)} existing lists managed by this script with prefix {prefix}.")
    return script_lists

  def get_zt_policy_by_name(self, name: str) -> Optional[Dict[str, Any]]:
    logger.info(f"Fetching Zero Trust Gateway policy by name: {name}...")

    def _get_policies():
      return self.cf.zero_trust.gateway.rules.list(account_id=self.account_id)

    policies_response = self._api_call_with_retry(_get_policies)

    if policies_response:
        for policy in policies_response:
            if policy.name == name:
                logger.info(f"Found existing policy {name} with ID {policy.id}.")
                return {
                    'id': policy.id,
                    'name': policy.name,
                    'description': getattr(policy, 'description', ''),
                    'action': getattr(policy, 'action', ''),
                    'enabled': getattr(policy, 'enabled', True),
                    'filters': getattr(policy, 'filters', []),
                    'traffic': getattr(policy, 'traffic', ''),
                    'precedence': getattr(policy, 'precedence', 0)
                }
    logger.info(f"Policy {name} not found.")
    return None

  def create_zt_list(self, name: str, items: List[str], description: str) -> Optional[str]:
    logger.info(f"Creating Zero Trust list: {name} with {len(items)} items.")

    def _create_list():
      return self.cf.zero_trust.gateway.lists.create(
        account_id=self.account_id,
        name=name,
        type="DOMAIN",
        description=description,
        items=[{"value": item} for item in items]
      )

    response = self._api_call_with_retry(_create_list)
    list_id = response.id if response else None
    if list_id:
      logger.info(f"Successfully created list {name} with ID {list_id}.")
    return list_id

  def update_zt_list(self, list_id: str, name: str, items: List[str], description: str) -> bool:
    logger.info(f"Updating Zero Trust list ID {list_id} ({name}) with {len(items)} items.")

    try:
      def _update_list():
        return self.cf.zero_trust.gateway.lists.update(
          list_id=list_id,
          account_id=self.account_id,
          name=name,
          description=description,
          items=[{"value": item} for item in items]
        )

      self._api_call_with_retry(_update_list)
      logger.info(f"Successfully updated list ID '{list_id}' ('{name}').")
      return True
    except Exception as e:
      logger.error(f"Failed to update list ID '{list_id}' ('{name}'): {e}")
      return False

  def delete_zt_list(self, list_id: str, list_name: str) -> bool:
    logger.info(f"Deleting Zero Trust list ID '{list_id}' ('{list_name}').")

    def _delete_list():
      return self.cf.zero_trust.gateway.lists.delete(
        list_id=list_id,
        account_id=self.account_id
      )

    self._api_call_with_retry(_delete_list)
    logger.info(f"Successfully deleted list ID '{list_id}' ('{list_name}').")
    return True

  def create_or_update_zt_gateway_dns_policy(self,
                                           policy_name: str,
                                           description: str,
                                           list_ids_for_policy: List[str],
                                           dns_location_id: Optional[str],
                                           existing_policy_details: Optional[Dict[str, Any]]) -> Optional[str]:

    # Constructing the DNS Policy Payload
    if list_ids_for_policy:
      # Format for traffic rule: "any(dns.domains[*] in $uuid1) or any(dns.domains[*] in $uuid2)"
      # The list ID in the rule needs to be the UUID without dashes.
      formatted_list_refs = [f"any(dns.domains[*] in ${list_id.replace('-', '')})" for list_id in list_ids_for_policy]
      traffic_expression = " or ".join(formatted_list_refs)
    else:
      traffic_expression = "1==0"  # No lists, policy effectively blocks nothing

    policy_data = {
      'name': policy_name,
      'description': description,
      'action': 'block',
      'enabled': True,
      'filters': ['dns'],
      'traffic': traffic_expression,
      'precedence': 11
    }

    # Add location_ids if provided
    if dns_location_id:
      policy_data['location_ids'] = [dns_location_id]

    if existing_policy_details:
        policy_id = existing_policy_details['id']
        logger.info(f"Updating existing policy {policy_name} (ID: {policy_id}) to reference {len(list_ids_for_policy)} list(s).")

        def _update_policy():
          return self.cf.zero_trust.gateway.rules.update(
            rule_id=policy_id,
            account_id=self.account_id,
            **policy_data
          )

        response = self._api_call_with_retry(_update_policy)
        logger.info(f"Successfully updated policy {policy_name}.")
        return policy_id
    else:
        logger.info(f"Creating new policy {policy_name} to reference {len(list_ids_for_policy)} list(s).")

        def _create_policy():
          return self.cf.zero_trust.gateway.rules.create(
            account_id=self.account_id,
            **policy_data
          )

        response = self._api_call_with_retry(_create_policy)
        new_policy_id = response.id if response else None
        if new_policy_id:
            logger.info(f"Successfully created policy {policy_name} with ID {new_policy_id}.")
        return new_policy_id

# --- Main Logic ---
def _check_env_vars() -> Tuple[str, str]:
  """Checks for required environment variables and returns them if found, otherwise exits."""
  account_id = CLOUDFLARE_ACCOUNT_ID
  api_token = CLOUDFLARE_API_TOKEN

  if not account_id or not api_token:
    logger.critical("CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_API_TOKEN environment variables are required.")
    sys.exit(1)

  if not DNS_LOCATION_ID:
    logger.warning("DNS_LOCATION_ID not provided. The adblock policy will not be explicitly tied to a specific location in its definition.")

  return account_id, api_token

def _load_desired_state_from_chunks(
    chunk_files_path_pattern: str, list_name_prefix: str, max_list_items: int, max_total_lists: int
) -> Dict[str, List[str]]:
  """Loads domain lists from chunk files with free tier limits."""
  desired_lists_from_files: Dict[str, List[str]] = {}
  chunk_files = sorted(glob.glob(os.path.join(PROCESSED_CHUNKS_DIR, chunk_files_path_pattern)))
  logger.info(f"Found {len(chunk_files)} chunk files in {PROCESSED_CHUNKS_DIR} matching pattern {chunk_files_path_pattern}.")

  if len(chunk_files) > max_total_lists:
    logger.warning(f"Found {len(chunk_files)} chunk files, but free tier limit is {max_total_lists} lists. Using first {max_total_lists} files.")
    chunk_files = chunk_files[:max_total_lists]

  for chunk_file_path in chunk_files:
    base_filename = os.path.basename(chunk_file_path)
    list_name_suffix = base_filename.replace(".txt", "").replace("_", "-")
    list_name = list_name_prefix + list_name_suffix

    try:
      with open(chunk_file_path, 'r') as f:
        domains = [line.strip() for line in f if line.strip()]
        if len(domains) > max_list_items:
            logger.warning(
                f"List {list_name} from file {chunk_file_path} has {len(domains)} items, "
                f"exceeding max of {max_list_items}. Truncating."
            )
            desired_lists_from_files[list_name] = domains[:max_list_items]
        elif domains:
            desired_lists_from_files[list_name] = domains
        else:
            logger.info(f"Chunk file {chunk_file_path} is empty. Skipping list creation for {list_name}.")
    except Exception as e:
      logger.error(f"Error reading or processing chunk file {chunk_file_path}: {e}")

  logger.info(f"Desired state: {len(desired_lists_from_files)} non-empty lists to be managed from files.")
  return desired_lists_from_files

def _reconcile_lists_with_hash_detection(
    desired_lists: Dict[str, List[str]], existing_cf_lists: Dict[str, Dict[str, Any]]
) -> Tuple[Dict[str, List[str]], Dict[str, Dict[str, Any]], Dict[str, str]]:
  """Determines list operations using hash-based change detection."""
  list_ops_create: Dict[str, List[str]] = {}
  list_ops_update: Dict[str, Dict[str, Any]] = {}  # name -> {'id': id, 'items': items}
  list_ops_delete: Dict[str, str] = {}            # name -> id

  for desired_name, desired_items in desired_lists.items():
    if desired_name in existing_cf_lists:
      existing_data = existing_cf_lists[desired_name]
      existing_description = existing_data.get('description', '')

      # Use hash-based change detection
      if has_list_changed(desired_items, existing_description):
        logger.info(f"List {desired_name} has changed (hash mismatch), scheduling for update.")
        list_ops_update[desired_name] = {
          'id': existing_data['id'],
          'items': desired_items
        }
      else:
        logger.info(f"List {desired_name} unchanged (hash match), skipping update.")
    else:
      logger.info(f"List {desired_name} doesn't exist, scheduling for creation.")
      list_ops_create[desired_name] = desired_items

  for existing_name, existing_data in existing_cf_lists.items():
    if existing_name not in desired_lists:
      logger.info(f"List {existing_name} no longer needed, scheduling for deletion.")
      list_ops_delete[existing_name] = existing_data['id']

  logger.info(f"List operations planned: Create: {len(list_ops_create)}, Update: {len(list_ops_update)}, Delete: {len(list_ops_delete)}")
  return list_ops_create, list_ops_update, list_ops_delete

def _execute_list_operations_and_get_ids(
    cf_manager: CloudflareManager,
    list_ops_create: Dict[str, List[str]],
    list_ops_update: Dict[str, Dict[str, Any]],
    existing_cf_lists: Dict[str, Dict[str, Any]]
) -> List[str]:
  """Executes create and update operations for lists and returns ALL managed list IDs."""
  managed_list_ids_for_policy: List[str] = []

  # Create new lists
  for name, items in list_ops_create.items():
    items_hash = calculate_list_hash(items)
    description = get_list_description_with_hash(f"Adblock list from {name}. Managed by script.", items_hash)
    new_list_id = cf_manager.create_zt_list(name, items, description)
    if new_list_id:
      logger.info(f"Successfully created list {name} with ID {new_list_id}.")
      managed_list_ids_for_policy.append(new_list_id)
    else:
      logger.error(f"Failed to create list {name}. It will not be included in the policy.")

  # Update existing lists
  for name, data in list_ops_update.items():
    items_hash = calculate_list_hash(data['items'])
    description = get_list_description_with_hash(f"Adblock list from {name}. Managed by script.", items_hash)
    if cf_manager.update_zt_list(data['id'], name, data['items'], description):
      logger.info(f"Successfully updated list {name} (ID: {data['id']}).")
      managed_list_ids_for_policy.append(data['id'])
    else:
      logger.error(f"Failed to update list {name} (ID: {data['id']}).")

  # Add IDs of existing lists that didn't need updates
  for name, data in existing_cf_lists.items():
    if name not in list_ops_create and name not in list_ops_update:
      managed_list_ids_for_policy.append(data['id'])
      logger.debug(f"Including unchanged list {name} (ID: {data['id']}) in policy.")

  return sorted(list(set(managed_list_ids_for_policy)))

def _delete_orphaned_lists(cf_manager: CloudflareManager, list_ops_delete: Dict[str, str]):
  """Deletes lists that are no longer desired."""
  if not list_ops_delete:
    logger.info("No lists to delete.")
    return

  logger.info(f"Deleting {len(list_ops_delete)} orphaned lists...")
  for name, list_id_to_delete in list_ops_delete.items():
    cf_manager.delete_zt_list(list_id_to_delete, name)

def main(max_list_items_arg: int, max_total_lists_arg: int):
  logger.info("Starting Cloudflare Adblock Management Script...")
  account_id, api_token = _check_env_vars()

  cf_manager = CloudflareManager(account_id, api_token)

  # 1. Get desired state from chunk files
  desired_lists_from_files = _load_desired_state_from_chunks(
    CHUNK_FILE_PATTERN, LIST_NAME_PREFIX, max_list_items_arg, max_total_lists_arg
  )

  if len(desired_lists_from_files) == 0:
    logger.warning("No valid lists found from chunk files. Exiting.")
    return

  # 2. Get current state from Cloudflare
  logger.info("Fetching current state from Cloudflare...")
  existing_cf_lists = cf_manager.get_all_zt_lists_by_prefix(LIST_NAME_PREFIX)
  existing_adblock_policy_details = cf_manager.get_zt_policy_by_name(POLICY_NAME)

  # 3. Reconcile Lists with Hash-based Change Detection
  list_ops_create, list_ops_update, list_ops_delete = _reconcile_lists_with_hash_detection(
    desired_lists_from_files, existing_cf_lists
  )

  # Skip processing if no changes needed
  if not list_ops_create and not list_ops_update and not list_ops_delete:
    logger.info("No list changes detected. Checking if policy update is needed...")
    all_current_list_ids = [data['id'] for data in existing_cf_lists.values()]
  else:
    # 4. Execute list operations (Create/Update) and get IDs for policy
    all_current_list_ids = _execute_list_operations_and_get_ids(
      cf_manager, list_ops_create, list_ops_update, existing_cf_lists
    )

  # 5. Update/Create Gateway DNS Policy
  logger.info(f"Updating policy {POLICY_NAME} to reference {len(all_current_list_ids)} lists.")
  cf_manager.create_or_update_zt_gateway_dns_policy(
    POLICY_NAME,
    POLICY_DESCRIPTION,
    all_current_list_ids,
    DNS_LOCATION_ID,
    existing_adblock_policy_details
  )

  # 6. Delete orphaned lists
  _delete_orphaned_lists(cf_manager, list_ops_delete)

  logger.info(f"{Colors.GREEN}Cloudflare Adblock Management Script finished.{Colors.RESET}")

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="Manage Cloudflare Zero Trust adblock lists and policy.")
  parser.add_argument(
      "max_list_items",
      type=int,
      help="Maximum number of items (domains) allowed per Cloudflare list."
  )
  parser.add_argument(
      "max_total_lists",
      type=int,
      help="Maximum number of lists to create/manage, typically constrained by Cloudflare free tier limits (e.g., 95)."
  )
  args = parser.parse_args()

  main(args.max_list_items, args.max_total_lists)
