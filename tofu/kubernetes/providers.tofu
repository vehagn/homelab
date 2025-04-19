terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.76.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.7.1"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = "2.0.1"
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
      passphrase = local.tofu_encryption_passphrase
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

locals {
  proxmox_api_token          = var.proxmox_api_token
  tofu_encryption_passphrase = var.tofu_encryption_passphrase
}

provider "proxmox" {
  endpoint = var.proxmox.endpoint
  insecure = var.proxmox.insecure

  api_token = local.proxmox_api_token
  ssh {
    agent    = true
    username = var.proxmox.username
  }
}

provider "restapi" {
  uri                  = var.proxmox.endpoint
  insecure             = var.proxmox.insecure
  write_returns_object = true

  headers = {
    "Content-Type"  = "application/json"
    "Authorization" = "PVEAPIToken=${local.proxmox_api_token}"
  }
}

provider "kubernetes" {
  host                   = module.talos.kube_config.kubernetes_client_configuration.host
  client_certificate     = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(module.talos.kube_config.kubernetes_client_configuration.ca_certificate)
}
