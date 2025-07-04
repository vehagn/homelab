provider "infisical" {
  host = var.infisical_domain
  auth = {
    universal = {
      client_id     = var.infisical_client_id
      client_secret = var.infisical_client_secret
    }
  }
}

locals {
  # Define the secrets to be created in Infisical
  # Keys are the names the secrets will have in Infisical
  # Values are the Tofu expressions for their content
  gcp_wif_secrets_to_infisical = {
    # Name the secrets as GitHub Actions will expect them
    "GCP_WORKLOAD_IDENTITY_PROVIDER" = google_iam_workload_identity_pool_provider.github_provider.name
    "GCP_SERVICE_ACCOUNT_EMAIL"      = google_service_account.tofu_dev_sa.email
  }
}

resource "infisical_secret" "gcp_wif_details" {
  for_each = local.gcp_wif_secrets_to_infisical

  name  = each.key   # The name of the secret in Infisical
  value = each.value # The value of the secret

  env_slug     = "prod"
  folder_path  = var.infisical_rw_secrets_path
  workspace_id = var.infisical_project_id

  # Ensure this runs after the resources providing the values are created/updated
  depends_on = [
    google_iam_workload_identity_pool_provider.github_provider,
    google_service_account.tofu_dev_sa
  ]
}
