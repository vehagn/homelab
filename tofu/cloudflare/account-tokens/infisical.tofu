provider "infisical" {
  host = var.infisical_domain
  auth = {
    universal = {
      client_id     = var.infisical_client_id
      client_secret = var.infisical_client_secret
    }
  }
}

# Store Zero Trust Account Token
resource "infisical_secret" "cloudflare_zero_trust_tofu_token" {
  name  = "TF_VAR_cloudflare_zero_trust_tofu_token"
  value = cloudflare_account_token.zero_trust_tofu_token.value

  env_slug     = var.branch_env
  folder_path  = var.infisical_rw_secrets_path
  workspace_id = var.infisical_project_id
}

# Store Email Account Token
resource "infisical_secret" "cloudflare_email_tofu_token" {
  name  = "TF_VAR_cloudflare_email_tofu_token"
  value = cloudflare_account_token.email_tofu_token.value

  env_slug     = var.branch_env
  folder_path  = var.infisical_rw_secrets_path
  workspace_id = var.infisical_project_id
}
