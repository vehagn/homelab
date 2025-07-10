provider "infisical" {
  host = var.infisical_domain
  auth = {
    universal = {
      client_id     = var.infisical_client_id
      client_secret = var.infisical_client_secret
    }
  }
}

# Store R2 access key
resource "infisical_secret" "cloudflare_r2_tofu_access_key" {
  name  = "TF_VAR_cloudflare_r2_tofu_access_key"
  value = cloudflare_account_token.r2_tofu_token.id

  env_slug     = var.branch_env
  folder_path  = var.infisical_rw_secrets_path
  workspace_id = var.infisical_project_id
}

# Store R2 access secret
resource "infisical_secret" "cloudflare_r2_tofu_access_secret" {
  name  = "TF_VAR_cloudflare_r2_tofu_access_secret"
  value = cloudflare_account_token.r2_tofu_token.value

  env_slug     = var.branch_env
  folder_path  = var.infisical_rw_secrets_path
  workspace_id = var.infisical_project_id
}
