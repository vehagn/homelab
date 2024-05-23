variable "cluster" {
  type = object({
    name          = string
    endpoint      = string
    talos_version = string
  })
}

variable "host_machines" {
  type = list(string)
}

variable "node_data" {
  description = "A map of node data"
  type = object({
    controlplanes = map(object({
      ip            = string
      mac_address   = string
      host_node     = string
      vm_id         = number
      cpu           = number
      ram_dedicated = number
      igpu          = optional(bool, false)
    }))
    workers = map(object({
      ip            = string
      mac_address   = string
      host_node     = string
      vm_id         = number
      cpu           = number
      ram_dedicated = number
    }))
  })
}
