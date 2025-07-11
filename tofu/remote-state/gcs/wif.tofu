# --- Workload Identity Federation for GitHub Actions ---

# Data source to get the current project details (like project number)
data "google_project" "current" {
  project_id = var.gcp_project_id # Assuming var.gcp_project_id is defined and set
}

# 1. Create a Workload Identity Pool
resource "google_iam_workload_identity_pool" "github_pool" {
  project                   = var.gcp_project_id
  workload_identity_pool_id = var.wif_config.pool_id
  display_name              = var.wif_config.pool_display_name
  description               = "Workload Identity Pool for GitHub Actions to access GCP resources for ${var.wif_config.github_owner}/${var.wif_config.github_repository}"
  disabled                  = false # Ensure it's enabled
}

# 2. Create a Workload Identity Provider within the pool for GitHub
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project                            = var.gcp_project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.wif_config.provider_id
  display_name                       = var.wif_config.provider_display_name
  description                        = "OIDC provider for GitHub Actions for repository ${var.wif_config.github_owner}/${var.wif_config.github_repository}"
  disabled                           = false # Ensure it's enabled

  oidc {
    issuer_uri        = "https://token.actions.githubusercontent.com"
    allowed_audiences = [] # Typically left empty for GitHub Actions OIDC.
  }

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    # "attribute.repository_owner" = "assertion.repository_owner" # Can be useful for org-level policies
  }

  # Attribute condition to restrict to your specific repository.
  # This is a key security feature.
  attribute_condition = "attribute.repository == '${var.wif_config.github_owner}/${var.wif_config.github_repository}'"
}

# 3. Grant the GitHub Actions Workload Identity permission to impersonate the tofu-dev-sa service account
# This allows workflows from your GitHub repository (matching the provider's condition)
# to generate tokens for the 'tofu-dev-sa' service account (defined in gcs.tofu).
resource "google_service_account_iam_member" "github_wif_user_for_tofu_sa" {
  service_account_id = google_service_account.tofu_dev_sa.name # From gcs.tofu
  role               = "roles/iam.workloadIdentityUser"

  # This member principal string identifies the GitHub Actions principals that can impersonate.
  # It uses the workload identity pool and the 'repository' attribute that we mapped.
  member = "principalSet://iam.googleapis.com/projects/${data.google_project.current.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_pool.workload_identity_pool_id}/attribute.repository/${var.wif_config.github_owner}/${var.wif_config.github_repository}"
}
