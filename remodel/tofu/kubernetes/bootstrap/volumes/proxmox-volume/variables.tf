variable "proxmox_api" {
  type = object({
    endpoint  = string
    insecure  = bool
    api_token = string
  })
  sensitive = true
}

variable "volume" {
  type = object({
    node = string
    name = string
    size = string
    storage = optional(string, "local-zfs")
    vmid = optional(number, 9999)
    format = optional(string, "raw")
  })
}
