variable "volume" {
  description = "Volume configuration"
  type = object({
    name               = string
    capacity           = string
    volume_handle      = string
    access_modes       = optional(list(string), ["ReadWriteOnce"])
    storage_class_name = optional(string, "proxmox-csi")
    fs_type            = optional(string, "ext4")
    driver             = optional(string, "csi.proxmox.sinextra.dev")
    volume_mode        = optional(string, "Filesystem")
    mount_options      = optional(list(string), ["noatime"])
    cache              = optional(string, "writethrough")
    ssd                = optional(bool, true)
    storage            = optional(string, "local-zfs")
  })
}
