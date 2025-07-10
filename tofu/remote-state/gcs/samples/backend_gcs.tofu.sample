terraform {
  backend "gcs" {
    bucket = var.bucket_name
    prefix = "remote-state/gcs/${var.branch_env}"
  }
}
