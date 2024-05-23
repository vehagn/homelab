resource "proxmox_virtual_environment_download_file" "truenas-scale-23" {
  provider     = proxmox.cantor
  node_name    = var.cantor.node_name
  content_type = "iso"
  datastore_id = "local"

  file_name          = "TrueNAS-SCALE-23.10.2.iso"
  url                = "https://download.sys.truenas.net/TrueNAS-SCALE-Cobia/23.10.2/TrueNAS-SCALE-23.10.2.iso"
  checksum           = "c2b0d6ef6ca6a9bf53a0ee9c50f8d0461fd5f12b962a8800e95d0bc3ef629edb"
  checksum_algorithm = "sha256"
}

resource "proxmox_virtual_environment_vm" "truenas-scale" {
  provider  = proxmox.cantor
  node_name = var.cantor.node_name

  name        = "truenas-scale"
  description = "True NAS scale"
  tags        = ["nas"]
  on_boot     = true
  vm_id       = 1000

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  bios          = "ovmf"

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 24576
  }

  network_device {
    bridge = "vmbr0"
  }

  efi_disk {
    datastore_id = "local-zfs"
    file_format = "raw" // To support qcow2 format
    type         = "4m"
  }

  disk {
    datastore_id = "local-zfs"
    file_id      = proxmox_virtual_environment_download_file.truenas-scale-23.id
    iothread     = true
    interface    = "scsi0"
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
    size         = 16
  }

  disk {
    datastore_id = "local-zfs"
    iothread     = true
    file_format  = "raw"
    interface    = "scsi1"
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
    size         = 128
  }

  boot_order = ["scsi1", "scsi0"]

  agent {
    enabled = true
  }

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 6.X.
  }

  initialization {
    dns {
      domain  = var.vm_dns.domain
      servers = var.vm_dns.servers
    }
    ip_config {
      ipv4 {
        address = "192.168.1.55/24"
        gateway = "192.168.1.1"
      }
    }

    datastore_id = "local-zfs"
    #    user_data_file_id = proxmox_virtual_environment_file.cloud-init-work-01.id
  }

  hostpci {
    device  = "hostpci0"
    mapping = "ASM1166-0"
    pcie    = true
    rombar  = true
    xvga    = false
  }

  //  hostpci {
  //    device = "hostpci1"
  //    mapping = "ASM1182e-0"
  //    pcie    = true
  //    rombar  = true
  //    xvga    = false
  //  }
  //
  //  hostpci {
  //    device = "hostpci2"
  //    mapping = "ASM1182e-1"
  //    pcie    = true
  //    rombar  = true
  //    xvga    = false
  //  }
  //
  //  hostpci {
  //    device = "hostpci3"
  //    mapping = "ASM1182e-2"
  //    pcie    = true
  //    rombar  = true
  //    xvga    = false
  //  }
  //
  //  hostpci {
  //    device = "hostpci4"
  //    mapping = "I226-V-0"
  //    pcie    = true
  //    rombar  = true
  //    xvga    = false
  //  }
  //
  //  hostpci {
  //    device = "hostpci5"
  //    mapping = "I226-V-1"
  //    pcie    = true
  //    rombar  = true
  //    xvga    = false
  //  }
}
