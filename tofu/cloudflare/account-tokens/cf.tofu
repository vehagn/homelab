locals {
  # https://developers.cloudflare.com/fundamentals/api/reference/permissions/#zone-permissions
  account_token_permissions_groups_map = {
    for perm in data.cloudflare_account_permission_groups.all.result : perm.name => perm.id
  }
}

# Get permission groups data to avoid hard-coded UUIDs
data "cloudflare_account_permission_groups" "all" {
  account_id = var.cloudflare_account_id
}

# Create Account token for Zero Trust access with proper permissions
resource "cloudflare_account_token" "zero_trust_tofu_token" {
  name = "Zero Trust Tofu Token"
  account_id = var.cloudflare_account_id

  policies = [{
    effect = "allow"
    permission_groups = [{
      id = locals.account_token_permissions_groups_map["Cloudflare Zero Trust"]  # Cloudflare Zero Trust:Edit
    },{
      id = locals.account_token_permissions_groups_map["DNS"]  # Cloudflare DNS:Edit
    }]
  }]
}

# Create Account token for Zero Trust access with proper permissions
resource "cloudflare_account_token" "email_tofu_token" {
  name = "Email Tofu Token"
  account_id = var.cloudflare_account_id

  policies = [{
    effect = "allow"
    permission_groups = [{
      id = locals.account_token_permissions_groups_map["Email Configuration Admin"]  # Email
    },{
      id = locals.account_token_permissions_groups_map["Email Integration Admin"]  # Email
    },{
      id = locals.account_token_permissions_groups_map["Workers Platform Admin"]  # Workers
    }]
  }]
}
