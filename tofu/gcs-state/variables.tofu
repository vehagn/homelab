# Define a variable for the Google Cloud project ID
variable "gcp_project_id" {
  description = "The Google Cloud project ID to deploy resources into."
  type        = string
}
# Define a variable for the Google Cloud region
variable "gcp_region" {
  description = "The Google Cloud region to deploy resources into."
  type        = string
}

# Define a variable for the GCS bucket name.
# Set this in .env file in root, which should automatically set it in devcontainer env.
variable "bucket_name" {
  description = "The globally unique name for the GCS bucket."
  type        = string
}

# Define a variable for part of gcs prefix.
# This should be set automatically based on branch logic in devcontainer.
variable "gcs_env" {
  description = "Part of GCS prefix."
  type        = string
}

variable "tofu_encryption_passphrase" {
  description = "The encryption passphrase for tofu state encryption."
  type        = string
  sensitive   = true
}

variable "gcp_sa_dev_emails" {
  description = "GCP SA Dev emails"
  type        = string
}
