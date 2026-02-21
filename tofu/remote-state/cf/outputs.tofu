output "bucket_name" {
  description = "The name of the R2 bucket."
  value       = cloudflare_r2_bucket.tofu_bucket.name
}

output "tofu_remote_state_token" {
  description = "The API token for the Tofu remote state bucket."
  value = {
    id   = cloudflare_account_token.r2_tofu_token.id
    name = cloudflare_account_token.r2_tofu_token.name
  }
  sensitive = true
}

# R2 access credentials for S3-compatible operations
output "r2_access_key_id" {
  description = "R2 access key ID for S3-compatible operations"
  value       = cloudflare_account_token.r2_tofu_token.id
  sensitive   = true
}

output "r2_secret_access_key" {
  description = "R2 secret access key for S3-compatible operations"
  value       = cloudflare_account_token.r2_tofu_token.value
  sensitive   = true
}

# R2 endpoint for S3-compatible operations
output "r2_endpoint" {
  description = "R2 S3-compatible endpoint"
  value       = "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com"
}

# Bucket URL for direct access
output "bucket_url" {
  description = "Direct URL to the R2 bucket"
  value       = "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com/${var.bucket_name}"
}
