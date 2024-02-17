variable "debian_12_generic" {
  description = "Cloud init image for Debian 12 Bookworm"
  type        = object({
    url                = string
    file_name          = string
    checksum           = string
    checksum_algorithm = string
  })
  default = {
    file_name          = "debian-12-generic-amd64-20240201-1644.img"
    url                = "https://cloud.debian.org/images/cloud/bookworm/20240201-1644/debian-12-generic-amd64-20240201-1644.qcow2"
    checksum           = "a75a053b097dd243d355253a926fb7be338df55cdb90905988ecf51062ceff97df79875921be7f72e179585d18222a5fe50d5d4e7e1816edfcb178c4d53253a4"
    checksum_algorithm = "sha512"
  }
}

resource "proxmox_virtual_environment_download_file" "debian_12_generic_image" {
  provider     = proxmox.euclid
  node_name    = var.euclid.node_name
  content_type = "iso"
  datastore_id = "local"

  file_name          = var.debian_12_generic.file_name
  url                = var.debian_12_generic.url
  checksum           = var.debian_12_generic.checksum
  checksum_algorithm = var.debian_12_generic.checksum_algorithm
}

# Make sure the "Snippets" content type is enabled on the target datastore in Proxmox before applying the configuration below.
# https://github.com/bpg/terraform-provider-proxmox/blob/main/docs/guides/cloud-init.md
resource "proxmox_virtual_environment_file" "cloud_config" {
  provider     = proxmox.euclid
  node_name    = var.euclid.node_name
  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    data = <<EOF
#cloud-config
users:
  - default
  - name: veh
    groups:
      - sudo
    shell: /bin/bash
    ssh_authorized_keys:
      - ${trimspace(data.local_file.ssh_public_key.content)}
    sudo: ALL=(ALL) NOPASSWD:ALL
runcmd:
    - apt update
    - apt install -y qemu-guest-agent net-tools
    - timedatectl set-timezone Europe/Oslo
    - systemctl enable qemu-guest-agent
    - systemctl start qemu-guest-agent
    - echo "done" > /tmp/cloud-config.done
    EOF

    file_name = "cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "debian_vm" {
  provider  = proxmox.euclid
  node_name = var.euclid.node_name

  name        = "k8s-controller-1"
  description = "Kubernetes Controller 1"
  tags        = ["k8s", "controller"]
  on_boot     = true
  bios        = "ovmf"

  vm_id = 2005

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

#    user_account {
#      username = "veh"
#      keys     = [trimspace(data.local_file.ssh_public_key.content)]
#    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  network_device {
    bridge = "vmbr0"
  }

  agent {
    enabled = true
  }

  machine = "q35"
  scsi_hardware = "virtio-scsi-single"

  efi_disk {
    datastore_id = "local-lvm"
    file_format = "raw" // To support qcow2 format
    type = "4m"
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.debian_12_generic_image.id
    interface    = "scsi0"
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
    size         = 64
  }

  boot_order = ["scsi0"]

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 5.X.
  }
}