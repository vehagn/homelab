variable "euclid" {
  description = "Euclid Proxmox server auth"
  type        = object({
    node_name = string
    username  = string
    api_token = string
  })
  sensitive = true
}
