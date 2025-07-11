terraform {
  backend "s3" {
    bucket                      = var.bucket_name
    key                         = "cloudflare/email-alias/${var.branch_env}/terraform.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    endpoints = {
      s3 = "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com"
    }
    access_key = var.cloudflare_r2_tofu_access_key
    secret_key = var.cloudflare_r2_tofu_access_secret
  }
}
