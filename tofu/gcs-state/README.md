## Overview

This OpenTofu module is responsible for provisioning the foundational infrastructure for managing OpenTofu state within Google Cloud Platform (GCP) and enabling secure CI/CD operations via GitHub Actions.

Key resources created and managed:

*   **GCS Bucket for Tofu Remote State**: A Google Cloud Storage (GCS) bucket is created to serve as a centralized and secure backend for storing OpenTofu state files. This includes versioning and lifecycle rules for state backups.
*   **Service Account (`tofu-dev-sa`)**: A dedicated Google Cloud Service Account named `tofu-dev-sa` is provisioned.
    *   **Purpose**: This service account is granted administrative permissions (`roles/storage.objectAdmin`) specifically on the GCS state bucket.
    *   It is also configured to be impersonated by authorized users and, importantly, by GitHub Actions workflows via Workload Identity Federation.
*   **Secrets Management with Infisical**: This module interacts with Infisical for managing sensitive configurations. It's important to distinguish between secrets managed *by this module* and secrets that *must be manually set up by the user* in Infisical:
    *   **User-Managed Secrets (to be created manually by the user in Infisical under the `/tofu` path in the `prod` Infisical environment):**
        *   `TF_VAR_tofu_encryption_passphrase`: The passphrase for OpenTofu state encryption. (Refer to "Instructions" section on how to generate and where to store).
        *   `TF_VAR_gcp_sa_dev_emails`: A JSON string array of user emails that are granted permission to impersonate the `tofu-dev-sa` service account (e.g., `'["user1@example.com","user2@example.com"]'`). (Refer to "Instructions" section on where to store).
    *   **Module-Managed Secrets (automatically created/updated by this Tofu module in Infisical under the path specified by `var.infisical_rw_secrets_path` (default: `/tofu_rw`) in the `prod` Infisical environment or set a different path in .env file in root for TF_VAR_infisical_rw_secrets_path):**
        *   `GCP_WORKLOAD_IDENTITY_PROVIDER`: The full Google Cloud resource name of the Workload Identity Provider created for GitHub Actions. This is used by GitHub Actions to authenticate to GCP.
        *   `GCP_SERVICE_ACCOUNT_EMAIL`: The email address of the `tofu-dev-sa` service account. This is also used by GitHub Actions during authentication to specify which service account to impersonate.

## Workload Identity Federation for GitHub Actions

This configuration (primarily in `wif.tofu`) sets up Google Cloud Workload Identity Federation, offering significant benefits:

*   **Enhanced Security:** Allows GitHub Actions to authenticate to Google Cloud and access resources (like the GCS state bucket) **without needing long-lived service account keys** stored as GitHub secrets. This is the Google-recommended best practice.
*   **Fine-grained Permissions:** The `tofu-dev-sa` service account has specific permissions (e.g., to manage the GCS state bucket). GitHub Actions only inherit these necessary permissions when they impersonate this service account.
*   **Auditable:** The impersonation events can be audited in Google Cloud.
*   **Infrastructure as Code:** The entire authentication mechanism for GitHub Actions is managed via OpenTofu, making it version-controlled, repeatable, and transparent.

After this OpenTofu configuration is applied, the `workload_identity_provider_name` and `tofu_dev_service_account_email` are pushed to Infisical (as `GCP_WORKLOAD_IDENTITY_PROVIDER` and `GCP_SERVICE_ACCOUNT_EMAIL` respectively, under the path defined by `var.infisical_rw_secrets_path`). Your GitHub Actions workflows (like `cf_adblock.yaml`) should then be configured to fetch these values from Infisical and use them in the `google-github-actions/auth` step for secure authentication to Google Cloud.

## Instructions

1. Setup [gcloud cli](/DEVCONTAINER.md).
2. Setup *.auto.tfvars files.
3. Setup .env file in root folder and commit it to git.
4. Setup TF_VAR_tofu_encryption_passphrase as per instruction below and save them to infisical in `/tofu` directory (or the directory defined in TF_VAR_infisical_ro_secrets_path in .env file in root).
    ```shell
    # TF_VAR_tofu_encryption_passphrase generation command
    openssl rand -base64 32
    ```
5. Setup TF_VAR_gcp_sa_dev_emails = ["email1@example.com","email2@example.com"] (emails you want to grant access to) below and save them to infisical in `/tofu` directory (or the directory defined in TF_VAR_infisical_ro_secrets_path in .env file in root).
6. Follow devcontainers docs [here](/DEVCONTAINER.md). If done properly, all secrets from infisical will be available in the container environment.


```shell
# Initialize tofu
tofu init
```

```shell
# Run tofu apply to create GCS bucket and permissions
tofu apply
```

```shell
# Copy GCS backend file
cp samples/backend_gcs.tofu.sample ./backend.tofu
```

```shell
# Re-initialize tofu to migrate state to GCS backend
# Double check TF_VAR_gcs_env is properly set to your env - prod/staging/dev - everytime you checkout a new branch.
tofu init -migrate-state
```
