data "terraform_remote_state" "gcs" {
  count = var.google_cloud.enable_remote_state ? 1 : 0
  backend = "gcs"
  config = {
    bucket          = "kj-homelab-tf-state"
    prefix          = "kubernetes/${data.external.git-branch.result.branch}"
    encryption_key  = try(data.bitwarden_secret.secrets["google_encryption_key"], null) != null ? data.bitwarden_secret.secrets["google_encryption_key"].value : var.google_cloud.encryption_key
    credentials     = try(data.bitwarden_secret.secrets["google_credentials"], null) != null ? data.bitwarden_secret.secrets["google_credentials"].value : file(var.google_cloud.credentials_file)
  }
}

data "terraform_remote_state" "local" {
  count = var.google_cloud.enable_remote_state ? 0 : 1
  backend = "local"
  config = {
    path = "${data.external.git-branch.result.branch}.tfstate"
  }
}
