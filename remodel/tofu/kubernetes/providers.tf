terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.31.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.60.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.5.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox.endpoint
  insecure = var.proxmox.insecure

  api_token = var.proxmox.api_token
  ssh {
    agent    = true
    username = var.proxmox.username
  }
}

provider "kubernetes" {
  host = module.talos.talos_kube_config.kubernetes_client_configuration.host
  client_certificate = base64decode(module.talos.talos_kube_config.kubernetes_client_configuration.client_certificate)
  client_key = base64decode(module.talos.talos_kube_config.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(module.talos.talos_kube_config.kubernetes_client_configuration.ca_certificate)
  #  ignore_labels = [
  #    "app.kubernetes.io/.*",
  #    "kustomize.toolkit.fluxcd.io/.*",
  #  ]
}
