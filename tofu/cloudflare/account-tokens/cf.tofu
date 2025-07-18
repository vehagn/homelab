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

# Create Account token for Zero Trust access with proper permissions
resource "cloudflare_account_token" "zero_trust_tofu_token" {
  name       = "Zero Trust Tofu Token"
  account_id = var.cloudflare_account_id

  policies = [{
    effect = "allow"
    permission_groups = [{
      id = local.api_token_permission_groups_map.account["Zero Trust Write"]
    }]
    resources = {
      "com.cloudflare.api.account.${var.cloudflare_account_id}" = "*"
    }
    }, {
    effect = "allow"
    permission_groups = [{
      id = local.api_token_permission_groups_map.account["Cloudflare Zero Trust Secure DNS Locations Write"]
    }]
    resources = {
      "com.cloudflare.api.account.${var.cloudflare_account_id}" = "*"
    }
    }, {
    effect = "allow"
    permission_groups = [{
      id = local.api_token_permission_groups_map.zone["DNS Write"]
    }]
    resources = {
      "com.cloudflare.api.account.zone.${var.cloudflare_zone_id}" = "*"
    }
  }]
}

# Create Account token for Zero Trust access with proper permissions
resource "cloudflare_account_token" "email_tofu_token" {
  name       = "Email Tofu Token"
  account_id = var.cloudflare_account_id

  policies = [{
    effect = "allow"
    permission_groups = [{
      id = local.api_token_permission_groups_map.account["Email Routing Addresses Write"]
    }]
    resources = {
      "com.cloudflare.api.account.${var.cloudflare_account_id}" = "*"
    }
    }, {
    effect = "allow"
    permission_groups = [{
      id = local.api_token_permission_groups_map.zone["Email Routing Rules Write"]
    }]
    resources = {
      "com.cloudflare.api.account.zone.${var.cloudflare_zone_id}" = "*"
    }
    }, {
    effect = "allow"
    permission_groups = [{
      id = local.api_token_permission_groups_map.account["Workers Scripts Write"]
    }]
    resources = {
      "com.cloudflare.api.account.${var.cloudflare_account_id}" = "*"
    }
  }]
}
