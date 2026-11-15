terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.33.0"
    }
    infisical = {
      source  = "infisical/infisical"
      version = ">= 0.15.7"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.3.4"
    }
  }
  encryption {
    key_provider "pbkdf2" "my_passphrase" {
      passphrase = var.tofu_encryption_passphrase
    }
    method "aes_gcm" "my_method" {
      keys = key_provider.pbkdf2.my_passphrase
    }
    state {
      method   = method.aes_gcm.my_method
      enforced = true
    }
    plan {
      method   = method.aes_gcm.my_method
      enforced = true
    }
  }
}

# Configure the Google Cloud provider
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
