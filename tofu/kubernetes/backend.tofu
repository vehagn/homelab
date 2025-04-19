terraform {
  backend "gcs" {
    bucket         = "kj-homelab-tf-state"
    prefix         = "kubernetes/${local.backend_environment}"
  }
}
