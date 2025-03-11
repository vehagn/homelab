terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">=2.35.1"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.70.1"
    }
  }
}
