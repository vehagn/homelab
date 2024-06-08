resource "proxmox_virtual_environment_vm" "k8s-ctrl-00" {
  provider  = proxmox.abel
  node_name = var.abel.node_name

  name        = var.k8s-ctrl-00.hostname
  description = "Talos Kubernetes Control Plane 00"
  tags        = ["k8s", "control-plane"]
  on_boot     = true
  vm_id       = 8100

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  bios          = "seabios"

  agent {
    enabled = true
  }

  cpu {
    cores = 8
    type  = "host"
    #type = "x86-64-v2-AES"
  }

  memory {
    dedicated = 24576
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = var.k8s-ctrl-00.mac_address
  }

  #  disk {
  #    datastore_id = "local-zfs"
  #    file_id      = proxmox_virtual_environment_file.talos_nocloud_image.id
  #    file_format  = "raw"
  #    interface    = "virtio0"
  #    size         = 20
  #  }

  disk {
    datastore_id = "local-zfs"
    interface    = "scsi0"
    iothread     = true
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
   # file_id      = proxmox_virtual_environment_download_file.talos_nocloud_image.id
    file_id      = proxmox_virtual_environment_file.talos_nocloud_image.id
    file_format  = "raw"
    size         = 20
  }

  #  disk {
  #    datastore_id = "local-zfs"
  #    iothread     = true
  #    file_id      = proxmox_virtual_environment_download_file.debian_12_bpo.id
  #    interface    = "scsi0"
  #    cache        = "writethrough"
  #    discard      = "on"
  #    ssd          = true
  #    size         = 32
  #  }

  boot_order = ["scsi0"]

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 6.X.
  }

  initialization {
    datastore_id      = "local-zfs"
    user_data_file_id = proxmox_virtual_environment_file.k8s-ctrl-00.id
#    dns {
#      domain  = "."
#      servers = ["1.1.1.1", "8.8.8.8"]
#    }
    ip_config {
      ipv4 {
        address = "${var.k8s-ctrl-00.ip}/24"
        gateway = "192.168.1.1"
      }
      ipv6 {
        address = "dhcp"
      }
    }

  }

  #  hostpci {
  #    # Passthrough iGPU
  #    device = "hostpci0"
  #    #id     = "0000:00:02"
  #    mapping = "iGPU"
  #    pcie    = true
  #    rombar  = true
  #    xvga    = false
  #  }
}

#output "ctrl_01_ipv4_address" {
#  depends_on = [proxmox_virtual_environment_vm.k8s-ctrl-00]
#  value      = proxmox_virtual_environment_vm.k8s-ctrl-00.ipv4_addresses[1][0]
#}
#
#resource "local_file" "ctrl-01-ip" {
#  content         = proxmox_virtual_environment_vm.k8s-ctrl-00.ipv4_addresses[1][0]
#  filename        = "output/ctrl-01-ip.txt"
#  file_permission = "0644"
#}

#module "kube-config" {
#  depends_on   = [local_file.ctrl-01-ip]
#  source       = "Invicton-Labs/shell-resource/external"
#  version      = "0.4.1"
#  command_unix = "ssh -o StrictHostKeyChecking=no ${var.vm_user}@${local_file.ctrl-01-ip.content} cat /home/${var.vm_user}/.kube/config"
#}
#
#resource "local_file" "kube-config" {
#  content         = module.kube-config.stdout
#  filename        = "output/config"
#  file_permission = "0600"
#}
#
#module "kubeadm-join" {
#  depends_on   = [local_file.kube-config]
#  source       = "Invicton-Labs/shell-resource/external"
#  version      = "0.4.1"
#  command_unix = "ssh -o StrictHostKeyChecking=no ${var.vm_user}@${local_file.ctrl-01-ip.content} /usr/bin/kubeadm token create --print-join-command"
#}
