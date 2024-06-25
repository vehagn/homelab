variable "proxmox_node" {
  type = object({
    name            = string
    endpoint        = string
    insecure        = bool
    username        = string
    api_token       = string
    image_datastore = string
  })
  sensitive = true
}

variable "talos_image" {
  type = object({
    base_url = string
    version  = string
  })
}

variable "host_machines" {
  type = list(string)
}

variable "cluster" {
  type = object({
    name          = string
    endpoint      = string
    talos_version = string
  })
}

variable "talos_nodes" {
  description = "Talos node configuration"
  type = object({
    nodes = map(object({
      host_node     = string
      machine_type  = string
      ip            = string
      mac_address   = string
      vm_id         = number
      cpu           = number
      ram_dedicated = number
      igpu = optional(bool, false)
    }))
  })
}
