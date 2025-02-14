terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.66.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = ">=0.6.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">=3.4.5"
    }
  }
}
