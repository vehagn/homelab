locals {
  infisical_environment = lookup(var.infisical.branch_env_mapping, data.external.git-branch.result.branch, "dev")
}

provider "infisical" {
  host = var.infisical_domain
  auth = {
    universal = {
      client_id     = var.infisical_client_id
      client_secret = var.infisical_client_secret
    }
  }
}

resource "infisical_secret" "created_secrets" {
  # Create one resource per entry in the input map
  for_each = var.secrets_to_create

  name  = each.key
  value = each.value

  env_slug     = local.infisical_environment
  folder_path  = var.infisical_rw_secrets_path
  workspace_id = var.infisical_project_id
}
