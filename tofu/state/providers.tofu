terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.44.0"
    }
  }
  encryption {
    key_provider "pbkdf2" "encryption_passphrase" {
      passphrase = var.encryption_passphrase
    }
    method "aes_gcm" "encryption_method" {
      keys = key_provider.pbkdf2.encryption_passphrase
    }
    state {
      method   = method.aes_gcm.encryption_method
      enforced = true
    }
    plan {
      method   = method.aes_gcm.encryption_method
      enforced = true
    }
  }
  backend "gcs" {
    bucket = var.bucket_name
    prefix = var.state_prefix
  }
}

provider "google" {
  project = var.gcp.project_id
  region  = var.gcp.region
}
