variable "tofu_encryption_passphrase" {
  description = "State encryption passphrase"
  type        = string
  sensitive   = true
  default     = null
}

variable "cloudflare_secondary_account_id" {
  type = string
}

variable "cloudflare_secondary_api_token" {
  type      = string
  sensitive = true
}

# Define a variable for the GCS bucket name
variable "bucket_name" {
  description = "The globally unique name for the GCS bucket."
  type        = string
}
