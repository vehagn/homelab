terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.57.0"
    }
    talos = {
      source = "siderolabs/talos"
      version = "0.5.0"
    }
  }
}

