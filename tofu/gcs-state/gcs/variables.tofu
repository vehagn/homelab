variable "bucket_name" {
  description = "Globally unique name for the GCS bucket"
  type        = string
}

variable "region" {
  description = "Google Cloud region to deploy resources into"
  type = string
}

variable "gcp_sa_dev_emails" {
  description = "GCP SA Dev emails"
  type        = list(string)
}
