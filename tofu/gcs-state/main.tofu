module "gcs" {
  source = "./gcs"

  region            = var.gcp.region
  bucket_name       = var.bucket_name
  gcp_sa_dev_emails = var.gcp_sa_dev_emails
}