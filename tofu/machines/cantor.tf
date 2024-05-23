provider "proxmox" {
  alias    = "cantor"
  #endpoint  = "https://proxmox.cantor.stonegarden.dev"
  endpoint  = "https://192.168.1.52:8006"
  insecure  = true

  api_token = var.cantor.api_token
  ssh {
    agent    = true
    username = var.cantor.username
  }

  tmp_dir = "/var/tmp"
}
