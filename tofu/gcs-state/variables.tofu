variable "encryption_passphrase" {
  description = "Encryption passphrase for Tofu state encryption"
  type        = string
  sensitive   = true
}

variable "gcp" {
  description = "Google Cloud project ID and region to deploy resources into"
  type = object({
    project_id = string,
    region     = string
  })
}

variable "bucket_name" {
  description = "Globally unique name for GCS bucket"
  type        = string
}

variable "state_prefix" {
  description = "State prefix in GCS bucket"
  type        = string
  default     = "tofu/gcs-state"
}

variable "gcp_sa_dev_emails" {
  description = "GCP SA Dev emails"
  type = list(string)
}

variable "wif_config" {
  description = "Configuration for Workload Identity Federation with GitHub Actions."
  type = object({
    github_owner          = string
    github_repository     = string
    pool_id               = string
    pool_display_name     = string
    provider_id           = string
    provider_display_name = string
  })
}
