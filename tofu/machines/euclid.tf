provider "proxmox" {
  alias    = "euclid"
  #endpoint  = "https://proxmox.euclid.stonegarden.dev"
  endpoint  = "https://192.168.1.42:8006"
  insecure  = true

  api_token = var.euclid.api_token
  ssh {
    agent    = true
    username = var.euclid.username
  }

  tmp_dir = "/var/tmp"
}
