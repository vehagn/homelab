terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.90.0"
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