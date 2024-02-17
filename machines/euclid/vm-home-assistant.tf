variable "haos_ova" {
  description = "Cloud init image for Home Assistant OS 11.5"
  type        = object({
    path      = string
    file_name = string
    checksum  = string
  })
  default = {
    path      = "images/haos_ova-11.5.qcow2"
    file_name = "haos_ova-11.5.img"
    checksum  = "1844150e53de638c9561a556ba18a7fb12ef082beed7a2da9be534f7075b65c6"
  }
}

resource "proxmox_virtual_environment_file" "haos_generic_image" {
  provider     = proxmox.euclid
  node_name    = var.euclid.node_name
  content_type = "iso"
  datastore_id = "local"

  source_file {
    path               = var.haos_ova.path
    file_name          = var.haos_ova.file_name
    checksum           = var.haos_ova.checksum
  }
}

resource "proxmox_virtual_environment_vm" "home_assistant" {
  provider  = proxmox.euclid
  node_name = var.euclid.node_name

  name        = "Home-Assistant"
  description = "Managed by OpenTofu"
  tags        = ["tofu", "home-assistant"]
  on_boot     = true
  bios        = "ovmf"

  vm_id = 1001

  tablet_device = false

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 4096
  }

  network_device {
    bridge = "vmbr0"
    mac_address = "BC:24:11:50:A6:33"
  }

  agent {
    enabled = true
  }

  efi_disk {
    datastore_id = "local-lvm"
    file_format = "raw" // To support qcow2 format
    type = "4m"
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_file.haos_generic_image.id
    interface    = "scsi0"
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
    size         = 64
  }

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 5.X.
  }

  lifecycle {
    prevent_destroy = true
  }
}