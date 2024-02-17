variable "euclid" {
  description = "Proxmox server configuration for Euclid machine"
  type        = object({
    node_name = string
    endpoint  = string
    insecure  = bool
  })
  default = {
    node_name = "euclid"
    endpoint  = "https://192.168.1.42:8006/"
    insecure  = true
  }
}

variable "euclid_auth" {
  description = "Auth for euclid proxmox server"
  type        = object({
    username = string
    password = string
  })
  sensitive = true
}