terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">=2.31.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.60.0"
    }
  }
}
