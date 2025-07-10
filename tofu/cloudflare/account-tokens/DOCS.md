## Overview

This OpenTofu module automates the creation of scoped Cloudflare Account API Tokens. By generating specific, permission-limited tokens, it enhances security by adhering to the principle of least privilege. Instead of using a master API token for all operations, other OpenTofu modules or CI/CD pipelines can use these tokens which only have the permissions necessary for their specific tasks.

## Key Resources

- **`cloudflare_account_token`**: This is the primary resource used to create the API tokens. Two distinct tokens are generated:
  - **`zero_trust_tofu_token`**: This token is granted a combination of permissions that allow it to manage Cloudflare Zero Trust configurations and DNS records. This is ideal for tasks like updating ad-block lists or other DNS-based filtering.
  - **`email_tofu_token`**: This token is configured with permissions to manage email routing rules and associated Workers. This is useful for automating email forwarding or processing.

- **`infisical_secret`**: For each token created, a corresponding secret is created in Infisical. This allows for the secure storage and retrieval of the token values. The secrets are named with a `TF_VAR_` prefix, making them easily consumable as environment variables in other OpenTofu configurations or scripts.

- **`cloudflare_account_permission_groups` data source**: This data source is used to dynamically fetch the available permission groups from the Cloudflare API. This avoids hardcoding permission group IDs, making the configuration more robust and adaptable to changes in the Cloudflare API.

## Instructions

### Prerequisites

Before applying this module, you must have the following in place:

1.  **Configured Remote State**: A remote backend (in this case, Cloudflare R2) must be fully configured and operational. The `backend.tf` file in this module is already configured to use the R2 bucket.
2.  **Infisical Project**: An Infisical project must exist, and you must have the necessary credentials (client ID, client secret, project ID) to authenticate and write secrets.
3.  **Environment Variables**: The following environment variables must be set in your execution environment (e.g., your devcontainer's `.env` file):
    - `TF_VAR_cloudflare_account_id`
    - `TF_VAR_cloudflare_master_account_api_token`
    - `TF_VAR_cloudflare_r2_tofu_access_key`
    - `TF_VAR_cloudflare_r2_tofu_access_secret`
    - `TF_VAR_bucket_name`
    - `TF_VAR_branch_env`
    - `TF_VAR_tofu_encryption_passphrase`
    - `TF_VAR_infisical_domain`
    - `TF_VAR_infisical_client_id`
    - `TF_VAR_infisical_client_secret`
    - `TF_VAR_infisical_project_id`

### Execution

Once the prerequisites are met, you can apply the configuration:

```bash
# Initialize tofu
tofu init

# Run tofu apply to create the tokens and secrets
tofu apply
```

After a successful apply, the generated tokens will be securely stored in your Infisical project under the path specified by `var.infisical_rw_secrets_path`.
