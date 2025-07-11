module "gcs" {
  source = "./gcs"

  gcp               = var.gcp
  bucket_name       = var.bucket_name
  gcp_sa_dev_emails = var.gcp_sa_dev_emails
}

module "wif" {
  source = "./wif"

  gcp                  = var.gcp
  service_account_name = module.gcs.tofu_service_account.name
  wif_config           = var.wif_config
}
