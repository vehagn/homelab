terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.48.2"
    }
  }
}

provider "proxmox" {
  alias    = "euclid"
  endpoint = var.euclid.endpoint
  insecure = var.euclid.insecure

  username = var.euclid_auth.username
  api_token = var.euclid_auth.api_token
  ssh {
    agent    = var.euclid_auth.agent
    username = var.euclid_auth.username
  }

  tmp_dir  = "/var/tmp"
}