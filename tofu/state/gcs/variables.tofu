variable "bucket_name" {
  description = "Globally unique name for the GCS bucket"
  type        = string
}

variable "gcp" {
  description = "Google Cloud project ID and region to deploy resources into"
  type = object({
    project_id = string,
    region     = string
  })
}
