module "gcs" {
  source = "./gcs"

  gcp         = var.gcp
  bucket_name = var.bucket_name
}
