## Overview

This OpenTofu module is responsible for provisioning the foundational infrastructure for managing OpenTofu state within Cloudflare R2. It automates the creation of the R2 bucket and generates the necessary S3-compatible access credentials for remote state storage.

## Key Resources

- **R2 Bucket for Tofu Remote State**: A Cloudflare R2 bucket is created to serve as a centralized and secure backend for storing OpenTofu state files. It is configured with versioning and lifecycle rules for state protection and management.
- **S3-Compatible R2 Access Credentials**: This module programmatically generates a Cloudflare Account API Token that is specifically scoped to provide S3-compatible read and write access to the created R2 bucket. These credentials (Access Key ID and Access Key Secret) are then securely stored in Infisical.
- **Secrets Management with Infisical**: This module interacts with Infisical for managing sensitive configurations.
  - **Input Secrets (Manually set up by the user in Infisical under the `/tofu` path in the appropriate Infisical environment):**
    - `TF_VAR_cloudflare_master_account_api_token`: A Cloudflare API Account token with permissions to create R2 buckets and Account API tokens.
    - `TF_VAR_cloudflare_account_id`: Your Cloudflare account ID.
    - `TF_VAR_tofu_encryption_passphrase`: Encryption passphrase for encrypting the state file.
    - The rest of the variables are automatically picked up from the devContainer environment.
    - Note: If you create these variables after loading the devContainer, you will need to run `source ~/.zshrc` again to load them into the environment.
  - **Other Secrets:**
    - `TF_VAR_bucket_name` - automatically set in the devcontainer when set in the `.env` file in the root folder.
    - `TF_VAR_branch_env`- automatically set in the devcontainer base on the current branch.
    - `TF_VAR_tofu_encryption_passphrase` - set it in infisical manually
    - `TF_VAR_infisical_domain` - automatically set in the devcontainer when set in the `.env` file in the root folder.
    - `TF_VAR_infisical_client_id` - automatically set in the devcontainer when set in the `.env` file in the root folder.
    - `TF_VAR_infisical_client_secret` - set it in [devcontainer](/.devcontainer/README.md) manually.
    - `TF_VAR_infisical_project_id` - automatically set in the devcontainer when set in the `.env` file in the root folder.
  - **Output Secrets (Automatically generated and stored by this Tofu module in Infisical under the path defined by `var.infisical_rw_secrets_path` (default: `/tofu_rw`) in the `prod` Infisical environment):**
    - `TF_VAR_cloudflare_r2_tofu_access_key`: The S3-compatible Access Key ID for the R2 bucket.
    - `TF_VAR_cloudflare_r2_tofu_access_secret`: The S3-compatible Secret Access Key for the R2 bucket.
- **OpenTofu State Encryption**: The OpenTofu state file (both local and remote) is encrypted at rest using a passphrase provided by the user. This ensures sensitive data within the state file is protected.

## Instructions

This module uses a two-phase approach for bootstrapping the remote state:

### Phase 1: Initial Apply (Local Backend)

Create the R2 bucket and generate access credentials using a local OpenTofu state.

```bash
# Copy local backend file
cp samples/backend_local.tofu.sample ./backend.tofu

# Initialize tofu
tofu init

# Run tofu apply to create R2 bucket and permissions
tofu apply
```

### Phase 2: Migrate State (Remote Backend)

Migrate your OpenTofu state to the newly provisioned R2 bucket.

```bash
# Copy R2 backend file
cp samples/backend_r2.tofu.sample ./backend.tofu

# Load Cloudflare tokens into the devcontainer environment
source ~/.zshrc

# If in local environment, you could run
# export TF_VAR_cloudflare_r2_tofu_access_key=$(tofu output -raw r2_access_key_id)
# export TF_VAR_cloudflare_r2_tofu_access_secret=$(tofu output -raw r2_secret_access_key)

# Re-initialize tofu to migrate state to R2 backend
# Double check TF_VAR_branch_env is properly set to your env - prod/staging/dev - everytime you checkout a new branch.
tofu init -migrate-state

# Remove any leftover local state files - careful, know what you are doing!
# rm *.tfstate*
```

Your OpenTofu state is now securely stored in the Cloudflare R2 bucket.
