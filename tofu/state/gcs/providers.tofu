terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.14.0"
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
