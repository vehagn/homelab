# Cloudflare Adblock & Malware DNS Filtering - Detailed Documentation

This document provides detailed explanations of the Cloudflare Adblock & Malware DNS Filtering setup, including its components, architecture, rationale, and execution steps. For a quick overview and getting started, please refer to the main [README.md](../README.md).

## Overview

This project enhances network security and user experience by filtering unwanted content at the DNS level using Cloudflare Zero Trust Gateway DNS policies. It employs a hybrid approach, combining OpenTofu for managing core infrastructure resources with a Python script and shell scripting for the dynamic management of large adblock domain lists and their associated Cloudflare policy.

## Key Components & Functionality

1.  **`adblock_urls.txt`**:
    - Contains URLs to external ad/malware domain lists (e.g., Hagezi). Each line should be a single URL. Lines starting with `#` are treated as comments and ignored. Empty lines are also ignored. This file is the primary source for defining which external lists are used to build the Cloudflare adblock lists. You can add or remove list URLs here to change the sources.

2.  **`chunk_adblock_lists.sh` (Shell Script)**:
    - **Purpose**: This script automates the process of downloading, consolidating, cleaning, sorting, and chunking the domain lists from the URLs specified in `adblock_urls.txt`. It handles potential duplicates by creating a unique sorted list before splitting. It splits the large list into smaller files (e.g., `adblock_chunk_000.txt`, `adblock_chunk_001.txt`, etc.) in the `./processed_adblock_chunks/` directory. This chunking is essential to comply with Cloudflare Zero Trust list item limits (currently 1000 items per list on the free tier). The script uses hashing and deterministic spillover to ensure that the mapping of domains to chunk files remains consistent between runs, even if the source lists have minor changes, minimizing unnecessary updates to Cloudflare lists.
    - **Usage**: This script is executed by the GitHub Action before the Python management script runs. It can also be run manually from the `tofu/cf-adblock/` directory (`bash ./chunk_adblock_lists.sh <MAX_DOMAINS_PER_BUCKET> <NUM_BUCKETS>`) to prepare the domain data locally.

3.  **OpenTofu Configuration (`.tofu` files in `./tofu/cf-adblock/`)**:
    - Manages the core Cloudflare Zero Trust infrastructure resources that are relatively static, have complex interdependencies best defined declaratively with Infrastructure as Code, or manage stateful components like the GCS backend.
    - **`backend.tofu`**: Configures the GCS backend for OpenTofu state management. This stores the state file (`tofu.tfstate`) in a Google Cloud Storage bucket, allowing multiple users or automated processes (like GitHub Actions) to work with the same infrastructure state securely (especially when combined with state encryption). The `prefix` (`cf-adblock/prod`) helps organize state files within the bucket.
    - **`providers.tofu`**: Defines the required external providers for OpenTofu to interact with Cloudflare and potentially other services like HTTP. It specifies the source (`cloudflare/cloudflare`, `hashicorp/http`) and acceptable version constraints (`>= 5.3.0`, `>=3.5.0`). It also configures state and plan encryption using PBKDF2 and AES-GCM methods, requiring a passphrase variable (`var.tofu_encryption_passphrase`).
    - **`variables.tofu`**: Defines input variables used by the OpenTofu configuration. These include sensitive variables for Cloudflare authentication (`cloudflare_account_id`, `cloudflare_zero_trust_tofu_token`, `tofu_encryption_passphrase`) and the GCS bucket name (`bucket_name`). Variable definitions specify type, description, and whether they are sensitive. Values are typically provided via environment variables (prefixed with `TF_VAR_`) or other OpenTofu input methods.
    - **`cloudflare_zero_trust_gateway_policy.tofu`**: Defines a specific DNS Gateway policy resource named `block_malware`. This policy is configured to block known threats based on Cloudflare's predefined security categories using a `traffic` expression (`any(dns.security_category[*] in {...})`). This policy is distinct from the ad-blocking policy, which is managed dynamically by the Python script.
    - **`cloudflare_zero_trust_dns_location.tofu`**: Sets up a custom DNS location resource (named "HomeLab") within Cloudflare Zero Trust. This resource defines the endpoints (DoH, DoT, IPv4, IPv6) that Cloudflare will provide for this location. It includes outputs (`dns_location_homelab`, `dns_location_homelab_id`) to make the dynamically assigned DNS endpoint details and the location's unique ID available after OpenTofu apply. This ID is then used by the Python script to associate the dynamically managed adblock policy with this specific location.

4.  **`manage_cloudflare_adblock.py` (Python Script)**:
    - **Purpose**: This script is the core logic for handling the dynamic aspects of the adblocking setup – specifically, the creation, update, and deletion of Cloudflare Zero Trust lists populated with adblock domains, and the management of the Gateway policy that uses these lists. It interacts directly with the Cloudflare API using the `cloudflare` Python library.
    - Reads the chunk files generated by `chunk_adblock_lists.sh` from the `./processed_adblock_chunks/` directory.
    - Uses a hash-based approach for change detection: it calculates a hash of the sorted domains within each chunk file and compares it to a hash embedded in the description of the corresponding Cloudflare Zero Trust list. This allows the script to efficiently determine if a list's content has actually changed, avoiding unnecessary API calls for unchanged lists.
    - Based on the comparison, it performs necessary operations: Creates new `cloudflare_zero_trust_list` resources for new chunk files, updates existing lists whose content has changed, and deletes lists in Cloudflare that no longer have a corresponding chunk file.
    - Manages the main "Block Ads - Managed by Script" Gateway policy. It constructs the `traffic` expression for this policy to include _all_ the IDs of the `cloudflare_zero_trust_list` resources that are currently being managed by the script.
    - **Usage**: This script is designed to be executed by the GitHub Action _after_ the chunking script has run and OpenTofu has applied its configuration. It takes arguments for the maximum items allowed per list and the maximum number of lists to manage, aligning with the chunking script's parameters and Cloudflare's limits. It requires Cloudflare account ID and API token, which are expected to be provided via environment variables (usually sourced from secrets).

## Rationale for Scripted List Management

Managing very large and frequently updated lists of domains (potentially thousands or tens of thousands) directly as items within `cloudflare_zero_trust_list` resources defined in HCL has several significant drawbacks when using OpenTofu:

- **State File Size and Processing**: Including thousands of domain entries directly as values within resource attributes in the OpenTofu state file can make the state file extremely large. A large state file can significantly slow down OpenTofu operations (`plan`, `apply`, `state list`, `state show`, etc.), increase memory usage, and make the state file cumbersome to work with, even with remote backends.
- **Plan Complexity**: Even minor changes in the source adblock lists (adding or removing a few domains) can result in massive, complex, and difficult-to-review diffs in OpenTofu plans. This makes it hard to understand the actual changes being applied and increases the risk of overlooking unintended consequences.
- **Update Performance**: Applying changes to a single resource with a very large number of items can be slow and may occasionally hit API rate limits or timeouts. While OpenTofu providers handle API interactions, orchestrating this outside of the core HCL resource definition provides more control.
- **Limit Management**: Manually splitting a large domain list into multiple `cloudflare_zero_trust_list` resources in HCL to adhere to Cloudflare's item limits per list (e.g., 1000) is a complex and error-prone task. A script can automate the chunking based on defined limits and manage the lifecycle of multiple list resources dynamically.
- **Efficient Change Detection**: Implementing efficient, content-based change detection (like checking if the _set_ of domains has changed, not just the order) directly in HCL is not straightforward or performant. A script allows for calculating and embedding a content hash (like SHA-256) in the list description or metadata. The script can then fetch the existing lists, compare hashes, and only perform API calls (create/update) for lists whose underlying domain content has genuinely changed. This significantly reduces unnecessary API traffic and state updates.
- **Dynamic Policy Referencing**: The "Block Ads" Gateway policy needs to reference _all_ the individual `cloudflare_zero_trust_list` IDs created from the chunks. As chunk files are added, removed, or change resulting in new list IDs, the policy definition needs to be updated. A script can dynamically fetch the IDs of all currently managed lists and construct the policy's `traffic` expression accordingly, ensuring the policy always reflects the complete set of adblock lists. Doing this purely in HCL with a dynamic number of resources referencing each other can be complex.

By using a Python script orchestrated alongside OpenTofu, we leverage OpenTofu for managing the stable, declarative infrastructure (backend state, providers, variables, the malware policy, and the DNS location which provides a stable ID) and the script for the dynamic, stateful, and data-intensive operations related to the adblock lists and their referencing policy via the Cloudflare API. This provides a more flexible, performant, and maintainable solution for this particular use case compared to a pure OpenTofu approach for the adblock lists themselves.

## GitHub Action Automation

The [GitHub Action](/.github/workflows/cf_adblock.yaml) workflow automates the process of updating the adblock lists and Cloudflare configuration on a regular schedule or via manual trigger.

Here is a breakdown of the steps in the workflow:

1.  **Triggers**: The workflow is configured to run on a monthly schedule (`cron: "0 0 1 * *"`, meaning at 00:00 UTC on the 1st day of every month) and can also be manually triggered via the GitHub Actions UI (`workflow_dispatch`).
2.  **Environment Variables**: Sets the `TF_VAR_branch_env` environment variable to `prod`, used by the OpenTofu backend configuration.
3.  **Permissions**: Grants necessary permissions for checking out the code (`contents: read`) and authenticating to Google Cloud using Workload Identity Federation (`id-token: write`).
4.  **Checkout repository**: Uses the `actions/checkout` action to clone the repository code onto the runner.
5.  **Load .env file to environment**: (Assumes a local `.env` file might be present for local devcontainer setup, although typically secrets are handled via Infisical in the action). This step sources environment variables from a `.env` file at the root of the repository, if it exists, and adds them to the GitHub Actions environment.
6.  **Load secrets to environment**: This crucial step authenticates to Infisical using a client secret (`secrets.INFISICAL_CLIENT_SECRET`) and runs a setup script (`./.devcontainer/setup_infisical.sh`). This script is responsible for fetching secrets stored in Infisical (including `TF_VAR_cloudflare_account_id`, `TF_VAR_cloudflare_zero_trust_tofu_token`, `TF_VAR_bucket_name`, `TF_VAR_tofu_encryption_passphrase`) and exporting them to a file. The workflow then reads this file, parses the `KEY=VALUE` lines, cleans up quotes, and adds these secrets as environment variables to the GitHub Actions runner for subsequent steps to use. The temporary file containing secrets is then removed.
7.  **Run Adblock List Chunking Script**: Executes the `chunk_adblock_lists.sh` script with arguments (e.g., `1000 90`) from within the `./tofu/cf-adblock/` directory. This script downloads the domain lists, processes them, and generates the chunk files in `./processed_adblock_chunks/`.
8.  **OpenTofu Init for cf-adblock**: Runs `tofu init` from the `./tofu/cf-adblock/` directory. This initializes the OpenTofu working directory, downloads necessary providers (Cloudflare, HTTP), and configures the GCS backend based on the `backend.tofu` file and the environment variables sourced from secrets.
9.  **OpenTofu Apply for cf-adblock**: Runs `tofu apply -auto-approve` from the `./tofu/cf-adblock/` directory. This applies the OpenTofu configuration, creating or updating the static resources defined in the `.tofu` files (providers, backend state, variables, malware policy, DNS location). The `-auto-approve` flag bypasses interactive approval, suitable for automation.
10. **Install Python dependencies**: Installs the required Python libraries for the management script using `pip3 install cloudflare`.
11. **Run Cloudflare Adblock Management Script**: (Note: This step appears commented out (`#- name:`) in the provided workflow file, but it is the intended final step to complete the update process). This step executes the `manage_cloudflare_adblock.py` script with necessary arguments (e.g., `1000 90`) from the `./tofu/cf-adblock/` directory. The script uses the `CLOUDFLARE_ACCOUNT_ID` and `CLOUDFLARE_API_TOKEN` environment variables (which were sourced from secrets and OpenTofu output) to authenticate to Cloudflare and manage the adblock lists and policy.

## Required Inputs (Variables & Secrets)

To successfully run this setup, both OpenTofu and the Python script require certain configuration inputs. These should be managed securely, ideally via a secrets management system like Infisical, and surfaced as environment variables for the workflow and manual execution.

- `TF_VAR_cloudflare_account_id`: Your Cloudflare Account ID where the Zero Trust configurations (lists, policies, locations) will be managed. This is used by both OpenTofu (for resources like the malware policy and DNS location) and the Python script (for list and policy management).
- `TF_VAR_cloudflare_zero_trust_tofu_token`: A Cloudflare API Token with the necessary permissions to manage Zero Trust Gateway lists, policies, and locations. This is a **sensitive secret** and must be kept secure. It is used by both OpenTofu and the Python script for authenticating with the Cloudflare API. Note: You might need to run `source ~/.zshrc` in your devcontainer to ensure the environment variables are loaded correctly after they are automatically set up in Infisical for the first time by account-tokens.
- `TF_VAR_bucket_name`: The globally unique name of the Google Cloud Storage bucket used for storing the OpenTofu state file. This is used by the OpenTofu backend configuration.
- `TF_VAR_tofu_encryption_passphrase`: A passphrase used to encrypt the OpenTofu state file stored in GCS. This is a **sensitive secret** and must be kept secure. Used by the OpenTofu `encryption` block.
- `TF_VAR_cloudflare_r2_tofu_access_key`: R2 remote state key, setup in infisical automatically by [cloudflare remote state](../../remote-state/cf/README.md).
- `TF_VAR_cloudflare_r2_tofu_access_secret`: R2 remote state secret, setup in infisical automatically by [cloudflare remote state](../../remote-state/cf/README.md).
- Note: You might need to run `source ~/.zshrc` in your devcontainer to ensure the environment variables are loaded correctly after they are automatically set up in Infisical for the first time by remote state.

## Manual Setup & Execution (Local Environment)

While the primary method for updating the lists and policy is the automated GitHub Action, you may need to run the process manually for testing, development, or initial setup in a local environment (like a devcontainer).

Note: By default, every month, the lists and policy are updated automatically via the [GitHub Action](/.github/workflows/cf_adblock.yaml).

To run manually:

1.  **Prerequisites**:
    - Ensure you have OpenTofu (or Terraform) installed.
    - Ensure you have Python 3 and `pip` installed.
    - Ensure you have `curl` and `grep` installed (usually available on Linux/macOS).
    - Ensure required environment variables (`TF_VAR_cloudflare_account_id`, `TF_VAR_cloudflare_zero_trust_tofu_token`, `TF_VAR_bucket_name`, `TF_VAR_tofu_encryption_passphrase`) are set in your local environment. If using Infisical, run the setup/export process to populate these variables in your shell session.
    - Navigate to the OpenTofu directory: `cd starter12/tofu/cf-adblock`.

2.  **Prepare Domain Lists**:
    - Run the chunking script to download, process, and split the domain lists. Replace `<MAX_DOMAINS_PER_BUCKET>` and `<NUM_BUCKETS>` with your desired limits (e.g., 1000 and 90).

    ```bash
    bash ./chunk_adblock_lists.sh <MAX_DOMAINS_PER_BUCKET> <NUM_BUCKETS>
    ```

    - Verify that chunk files (`adblock_chunk_*.txt`) have been created in the `./processed_adblock_chunks/` directory.

3.  **Initialize OpenTofu**:
    - Initialize the OpenTofu working directory. This sets up the backend configuration and downloads the required provider plugins based on your `providers.tofu` and `backend.tofu` files and environment variables.

    ```bash
    tofu init
    ```

4.  **Apply Static OpenTofu Resources**:
    - Run `tofu apply` to create or update the OpenTofu-managed resources (GCS backend state setup, providers configuration, variables, the malware policy, and the DNS location). Review the plan shown by OpenTofu carefully before confirming the apply.

    ```bash
    tofu apply
    ```

5.  **Install Python dependencies**:
    - Install the necessary Python library for interacting with the Cloudflare API.

    ```bash
    pip install cloudflare
    ```

6.  **Run Dynamic List Management Script**:
    - Execute the Python script to manage the adblock lists and policy in Cloudflare. Provide the same limits used for the chunking script. The script will use the environment variables (`CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_API_TOKEN`) for authentication and configuration.
    ```bash
    python3 manage_cloudflare_adblock.py <MAX_DOMAINS_PER_BUCKET> <NUM_BUCKETS>
    ```

This sequence of manual steps mirrors the automation in the GitHub Action and allows you to update the Cloudflare adblock configuration from your local environment.

### Commands

Here's a quick overview of the main steps (run from the `./tofu/cf-adblock/` directory):

```bash
# Prepare Domain Lists: Download, process, and split domains into chunks
bash ./chunk_adblock_lists.sh <MAX_DOMAINS_PER_BUCKET> <NUM_BUCKETS>

# Initialize OpenTofu working directory and backend
tofu init

# Apply Static OpenTofu Resources (backend state, providers, malware policy, DNS location)
# Review plan carefully before confirming!
tofu apply

# Install Python dependencies for the management script
pip install cloudflare

# Run Dynamic List Management Script to manage Cloudflare lists and adblock policy
python3 manage_cloudflare_adblock.py <MAX_DOMAINS_PER_BUCKET> <NUM_BUCKETS>
```

## Acknowledgements

This part of cloudflare ad-blocking was inspired by Marco Lancini's [blog post](https://blog.marcolancini.it/2022/blog-serverless-ad-blocking-with-cloudflare-gateway/) on serverless ad-blocking with Cloudflare Gateway.
