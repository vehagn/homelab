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
