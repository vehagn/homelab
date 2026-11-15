locals {
  # Create a nested map: scope -> permission_name -> id
  api_token_permission_groups_map = {
    account = {
      for perm in data.cloudflare_account_api_token_permission_groups_list.all.result :
      perm.name => perm.id
      if contains(perm.scopes, "com.cloudflare.api.account")
    }
    zone = {
      for perm in data.cloudflare_account_api_token_permission_groups_list.all.result :
      perm.name => perm.id
      if contains(perm.scopes, "com.cloudflare.api.account.zone")
    }
    # Add R2 scope mapping
    r2 = {
      for perm in data.cloudflare_account_api_token_permission_groups_list.all.result :
      perm.name => perm.id
      if contains(perm.scopes, "com.cloudflare.edge.r2.bucket")
    }
  }
}

# Get API token permission groups data
data "cloudflare_account_api_token_permission_groups_list" "all" {
  account_id = var.cloudflare_account_id
}

# Create R2 bucket for remote state
resource "cloudflare_r2_bucket" "tofu_bucket" {
  account_id = var.cloudflare_account_id
  name       = var.bucket_name
}

# Create Account token for R2 access with proper permissions
resource "cloudflare_account_token" "r2_tofu_token" {
  name       = "R2 Tofu Remote State Token"
  account_id = var.cloudflare_account_id

  policies = [{
    effect = "allow"
    permission_groups = [{
      id = local.api_token_permission_groups_map.r2["Workers R2 Storage Bucket Item Write"]
    }]
    resources = {
      "com.cloudflare.edge.r2.bucket.${var.cloudflare_account_id}_default_${var.bucket_name}" = "*"
    }
  }]
}
