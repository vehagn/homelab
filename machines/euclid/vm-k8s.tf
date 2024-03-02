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

resource "proxmox_virtual_environment_download_file" "almalinux_9_3_generic_image" {
  provider     = proxmox.euclid
  node_name    = var.euclid.node_name
  content_type = "iso"
  datastore_id = "local"

  file_name          = "almalinux-9.3-x86_64-minimal.img"
  url                = "https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-9.3-20231113.x86_64.qcow2"
  checksum           = "6bbd060c971fd827a544c7e5e991a7d9e44460a449d2d058a0bb1290dec5a114"
  checksum_algorithm = "sha256"
}

# Make sure the "Snippets" content type is enabled on the target datastore in Proxmox before applying the configuration below.
# https://github.com/bpg/terraform-provider-proxmox/blob/main/docs/guides/cloud-init.md
resource "proxmox_virtual_environment_file" "cloud_init_user" {
  provider     = proxmox.euclid
  node_name    = var.euclid.node_name
  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    data = templatefile("./cloud-init/user.yaml", {
      username = "veh"
      pub_key  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEiRlOx9+OlVr3EkEMyYNc0WiljPAHzCX0pHHJeHQG7"
      hostname = "k8s-controller-1"
    })
    file_name = "cloud-init-user.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "test_vm" {
  provider  = proxmox.euclid
  node_name = var.euclid.node_name

  name        = "test-machine"
  description = "Kubernetes Controller 1"
  tags        = ["k8s", "controller"]
  on_boot     = true
  bios        = "ovmf"

  vm_id = 2005

  initialization {
    ip_config {
      ipv4 {
        #address = "dhcp"
        address = "192.168.1.60/24"
        gateway = "192.168.1.1"
      }
    }

    datastore_id = "local-zfs"
    user_data_file_id   = proxmox_virtual_environment_file.cloud_init_user.id
  }

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = "BC:24:11:2E:87:12"
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
    size         = 64
  }

  boot_order = ["scsi0"]

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 5.X.
  }
}

output "controller_1_ipv4_address" {
  depends_on = [proxmox_virtual_environment_vm.test_vm]
  value = proxmox_virtual_environment_vm.test_vm.ipv4_addresses[1][0]
}

resource "local_file" "controller_1_ip" {
  content  = proxmox_virtual_environment_vm.test_vm.ipv4_addresses[1][0]
  filename = "controller-1-ip.txt"
  file_permission = "0644"
}