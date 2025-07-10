variable "tofu_encryption_passphrase" {
  description = "State encryption passphrase"
  type        = string
  sensitive   = true
  default     = null
}

variable "cloudflare_account_id" {
  type = string
}

variable "cloudflare_zero_trust_tofu_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_r2_tofu_access_key" {
  type        = string
  description = "The Cloudflare R2 access key for tofu remote state."
  sensitive   = true
}

variable "cloudflare_r2_tofu_access_secret" {
  type        = string
  description = "The Cloudflare R2 access secret for tofu remote state."
  sensitive   = true
}

# Define a variable for the bucket name
variable "bucket_name" {
  description = "The globally unique name for the bucket."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be lowercase, alphanumeric, and hyphens only."
  }

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters."
  }
}

# Define a variable for part of bucket prefix.
# This should be set automatically based on branch logic in devcontainer.
variable "branch_env" {
  description = "Part of bucket prefix."
  type        = string
}
