terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.46.3"
    }
  }
}

provider "proxmox" {
  alias    = "euclid"
  endpoint = var.euclid.endpoint
  insecure = var.euclid.insecure

  username = var.euclid_auth.username
  password = var.euclid_auth.password

  tmp_dir  = "/var/tmp"
}