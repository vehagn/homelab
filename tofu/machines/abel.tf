variable "abel" {
  description = "Abel Proxmox server auth"
  type        = object({
    node_name = string
    username  = string
    api_token = string
  })
  sensitive = true
}

provider "proxmox" {
  alias    = "abel"
  #endpoint  = "https://proxmox.abel.stonegarden.dev"
  endpoint  = "https://192.168.1.62:8006"
  insecure  = true

  api_token = var.abel.api_token
  ssh {
    agent    = true
    username = var.abel.username
  }

  tmp_dir = "/var/tmp"
}
