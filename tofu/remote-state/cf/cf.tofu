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

# Create R2 bucket for remote state
resource "cloudflare_r2_bucket" "tofu_bucket" {
  account_id = var.cloudflare_account_id
  name       = var.bucket_name
  location   = "auto"

  # Add versioning for state protection
  versioning = {
    enabled = true
  }

  # Lifecycle rules for state management
  lifecycle_rule {
    id     = "state_version_management"
    status = "Enabled"

    # Keep non-current versions for 30 days
    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    # Abort incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # Apply to all objects in the bucket
    filter {
      prefix = ""
    }
  }
}

# Create Account token for R2 access with proper permissions
resource "cloudflare_account_token" "r2_tofu_token" {
  name = "R2 Tofu Remote State Token"
  account_id = var.cloudflare_account_id

  policies = [{
    effect = "allow"
    permission_groups = [{
      id = locals.account_token_permissions_groups_map["Cloudflare R2 Admin"]  # Object Storage:Edit
    }]
    resources = {
      "com.cloudflare.api.account.${var.cloudflare_account_id}.r2.bucket.${var.bucket_name}" = "*"
    }
  }]
}
