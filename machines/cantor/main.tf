terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.50.0"
    }
  }
}

provider "proxmox" {
  alias    = "cantor"
  endpoint = var.cantor.endpoint
  insecure = var.cantor.insecure

  api_token = var.cantor_auth.api_token
  ssh {
    agent    = true
    username = var.cantor_auth.username
  }

  tmp_dir = "/var/tmp"
}