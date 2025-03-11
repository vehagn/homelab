variable "proxmox_cluster" {
  type = object({
    cluster_name = string
    endpoint     = string
    insecure     = bool
    username     = string
  })
}

variable "proxmox_api_token" {
  type      = string
  sensitive = true
}

variable "talos_image" {
  description = "Talos image configuration"
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
  type = object({
    name            = string
    endpoint        = string
    gateway         = string
    talos_version   = string
    proxmox_cluster = string
  })
}

variable "cluster_nodes" {
  type = map(object({
    host_node     = string
    machine_type  = string
    datastore_id = optional(string, "local-zfs")
    ip            = string
    mac_address   = string
    vm_id         = number
    cpu           = number
    ram_dedicated = number
    update = optional(bool, false)
    igpu = optional(bool, false)
  }))
}

variable "cluster_volumes" {
  type = map(
    object({
      node = string
      size = string
      storage = optional(string, "local-zfs")
      vmid = optional(number, 9999)
      format = optional(string, "raw")
    })
  )
}

variable "create_sealed_secret_certificates" {
  type    = bool
  default = true
}
