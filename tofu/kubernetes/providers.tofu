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
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = ">= 0.13.6"
    }
  }
}

locals {
  proxmox_api_token = try(data.bitwarden_secret.secrets["proxmox_api_token"], null) != null ? data.bitwarden_secret.secrets["proxmox_api_token"].value : var.proxmox_api_token
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

provider "bitwarden" {
  alias  = "ro"
  access_token = var.bws_access_token_ro
  experimental {
    embedded_client = true
  }
}

provider "bitwarden" {
  alias  = "rw"
  access_token = var.bws_access_token_rw
  experimental {
    embedded_client = true
  }
}
