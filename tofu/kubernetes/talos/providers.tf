terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.70.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = ">=0.7.1"
    }
    http = {
      source  = "hashicorp/http"
      version = ">=3.4.5"
    }
  }
}
