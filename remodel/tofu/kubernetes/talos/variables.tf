variable "talos_image" {
  type = object({
    factory_url = optional(string, "https://factory.talos.dev")
    schematic = string
    version   = string
    update_schematic = optional(string)
    update_version = optional(string)
    arch = optional(string, "amd64")
    platform = optional(string, "nocloud")
    proxmox_datastore = optional(string, "local")
  })
}

variable "cluster_config" {
  description = "Talos node configuration"
  type = object({

    cluster_name    = string
    proxmox_cluster = string
    endpoint        = string
    talos_version   = string

    nodes = map(object({
      host_node     = string
      machine_type  = string
      ip            = string
      mac_address   = string
      vm_id         = number
      cpu           = number
      ram_dedicated = number
      update = optional(bool, false)
      igpu = optional(bool, false)
    }))
  })
}

variable "cilium" {
  type = object({
    values  = string
    install = string
  })
}