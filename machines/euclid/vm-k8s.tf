resource "proxmox_virtual_environment_download_file" "debian_12_generic_image" {
  provider     = proxmox.euclid
  node_name    = var.euclid.node_name
  content_type = "iso"
  datastore_id = "local"

  file_name          = "debian-12-generic-amd64-20240201-1644.img"
  url                = "https://cloud.debian.org/images/cloud/bookworm/20240211-1654/debian-12-generic-amd64-20240211-1654.qcow2"
  checksum           = "b679398972ba45a60574d9202c4f97ea647dd3577e857407138b73b71a3c3c039804e40aac2f877f3969676b6c8a1ebdb4f2d67a4efa6301c21e349e37d43ef5"
  checksum_algorithm = "sha512"
}

# Make sure the "Snippets" content type is enabled on the target datastore in Proxmox before applying the configuration below.
# https://github.com/bpg/terraform-provider-proxmox/blob/main/docs/guides/cloud-init.md
resource "proxmox_virtual_environment_file" "cloud-init-ctrl-01" {
  provider     = proxmox.euclid
  node_name    = var.euclid.node_name
  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    data = templatefile("./cloud-init/user.yaml", {
      username = var.vm_user
      pub_key  = var.vm_pub-key
      hostname = "k8s-ctrl-01"
    })
    file_name = "cloud-init-k8s-ctrl-01.yaml"
  }
}

resource "proxmox_virtual_environment_file" "cloud-init-work-01" {
  provider     = proxmox.euclid
  node_name    = var.euclid.node_name
  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    data = templatefile("./cloud-init/user.yaml", {
      username = var.vm_user
      pub_key  = var.vm_pub-key
      hostname = "k8s-work-01"
    })
    file_name = "cloud-init-k8s-work-01.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "k8s-ctrl-01" {
  provider  = proxmox.euclid
  node_name = var.euclid.node_name

  name        = "k8s-ctrl-01"
  description = "Kubernetes Control Plane 01"
  tags        = ["k8s", "control-plane"]
  on_boot     = true
  bios        = "ovmf"

  vm_id = 8001

  initialization {
    ip_config {
      ipv4 {
        #address = "dhcp"
        address = "192.168.1.100/24"
        gateway = "192.168.1.1"
      }
    }

    datastore_id      = "local-zfs"
    user_data_file_id = proxmox_virtual_environment_file.cloud-init-ctrl-01.id
  }

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 4096
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = "BC:24:11:2E:C0:01"
  }

  agent {
    enabled = true
  }

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"

  efi_disk {
    datastore_id = "local-zfs"
    file_format  = "raw" // To support qcow2 format
    type         = "4m"
  }

  disk {
    datastore_id = "local-zfs"
    file_id      = proxmox_virtual_environment_download_file.debian_12_generic_image.id
    interface    = "scsi0"
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
    size         = 32
  }

  boot_order = ["scsi0"]

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 5.X.
  }
}

resource "proxmox_virtual_environment_vm" "k8s-work-01" {
  provider  = proxmox.euclid
  node_name = var.euclid.node_name

  name        = "k8s-work-01"
  description = "Kubernetes Worker 01"
  tags        = ["k8s", "worker"]
  on_boot     = true
  bios        = "ovmf"

  vm_id = 8101

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.1.110/24"
        gateway = "192.168.1.1"
      }
    }

    datastore_id      = "local-zfs"
    user_data_file_id = proxmox_virtual_environment_file.cloud-init-work-01.id
  }

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = "BC:24:11:2E:AE:01"
  }

  agent {
    enabled = true
  }

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"

  efi_disk {
    datastore_id = "local-zfs"
    file_format  = "raw" // To support qcow2 format
    type         = "4m"
  }

  disk {
    datastore_id = "local-zfs"
    file_id      = proxmox_virtual_environment_download_file.debian_12_generic_image.id
    interface    = "scsi0"
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
    size         = 32
  }

  boot_order = ["scsi0"]

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 5.X.
  }

  hostpci {
    # Passthrough iGPU
    device = "hostpci0"
    id     = "0000:00:02"
    pcie   = true
    rombar = true
    xvga   = false
  }

}

output "ctrl_01_ipv4_address" {
  depends_on = [proxmox_virtual_environment_vm.k8s-ctrl-01]
  value      = proxmox_virtual_environment_vm.k8s-ctrl-01.ipv4_addresses[1][0]
}

output "work_01_ipv4_address" {
  depends_on = [proxmox_virtual_environment_vm.k8s-work-01]
  value      = proxmox_virtual_environment_vm.k8s-work-01.ipv4_addresses[1][0]
}

resource "local_file" "ctrl_01_ip" {
  content         = proxmox_virtual_environment_vm.k8s-ctrl-01.ipv4_addresses[1][0]
  filename        = "output/ctrl-01-ip.txt"
  file_permission = "0644"
}

resource "local_file" "work_01_ip" {
  content         = proxmox_virtual_environment_vm.k8s-work-01.ipv4_addresses[1][0]
  filename        = "output/work-01-ip.txt"
  file_permission = "0644"
}
