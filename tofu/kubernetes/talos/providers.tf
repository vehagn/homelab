terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.60.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = ">=0.6.0-alpha.1"
    }
  }
}
