
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.6.0"
    }
    infisical = {
      source  = "infisical/infisical"
      version = ">= 0.15.21"
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

provider "cloudflare" {
  api_token = var.cloudflare_master_account_api_token
}
