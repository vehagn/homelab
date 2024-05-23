resource "proxmox_virtual_environment_vm" "home_assistant" {
  provider  = proxmox.euclid
  node_name = var.euclid.node_name

  name          = "Home-Assistant"
  description   = "Managed by OpenTofu"
  tags          = ["home-assistant"]
  on_boot       = true
  bios          = "ovmf"
  scsi_hardware = "virtio-scsi-single"

  vm_id = 1000

  tablet_device = false

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 4096
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = "BC:24:11:50:A6:33"
  }

  agent {
    enabled = true
  }

  efi_disk {
    datastore_id = "local-zfs"
    file_format = "raw" // To support qcow2 format
    type         = "4m"
  }

  disk {
    datastore_id = "local-zfs"
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
