terraform {
  backend "gcs" {
    bucket = var.bucket_name
    prefix = "cf-adblock/prod"
  }
}
