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

variable "haos_version" {
  type = string
}

variable "haos_download_url" {
  type    = string
  default = "https://github.com/home-assistant/operating-system/releases/download"
}

variable "local_file" {
  type    = string
  default = "home-assistant/haos_ova.qcow2"
}
