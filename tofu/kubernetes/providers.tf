terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.35.1"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.70.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = ">=0.7.1"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = ">=1.20.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_cluster.endpoint
  insecure = var.proxmox_cluster.insecure

  api_token = var.proxmox_api_token
  ssh {
    agent    = true
    username = var.proxmox_cluster.username
  }
}

provider "restapi" {
  uri                  = var.proxmox_cluster.endpoint
  insecure             = var.proxmox_cluster.insecure
  write_returns_object = true

  headers = {
    "Content-Type"  = "application/json"
    "Authorization" = "PVEAPIToken=${var.proxmox_api_token}"
  }
}

provider "kubernetes" {
  host = module.talos.kube_config.kubernetes_client_configuration.host
  client_certificate = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_certificate)
  client_key = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(module.talos.kube_config.kubernetes_client_configuration.ca_certificate)
}
