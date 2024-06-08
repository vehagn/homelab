#resource "proxmox_virtual_environment_vm" "k8s-ctrl-02" {
#  provider  = proxmox.abel
#  node_name = var.euclid.node_name
#
#  name        = var.k8s-ctrl-02.hostname
#  description = "Kubernetes Control Plane 02"
#  tags        = ["k8s", "control-plane"]
#  on_boot     = true
#  vm_id       = 8002
#
#  machine       = "q35"
#  scsi_hardware = "virtio-scsi-single"
#  bios          = "seabios"
#
#  cpu {
#    cores = 4
#    type  = "host"
#  }
#
#  memory {
#    dedicated = 24576
#  }
#
#  network_device {
#    bridge      = "vmbr0"
#    mac_address = var.k8s-ctrl-02.mac_address
#  }
#
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
#
#  boot_order = ["scsi0"]
#
#  agent {
#    enabled = true
#  }
#
#  operating_system {
#    type = "l26" # Linux Kernel 2.6 - 6.X.
#  }
#
#  initialization {
#    dns {
#      domain  = var.vm_dns.domain
#      servers = var.vm_dns.servers
#    }
#    ip_config {
#      ipv4 {
#        address = var.k8s-ctrl-02.ip
#        gateway = "192.168.1.1"
#      }
#    }
#
#    datastore_id      = "local-zfs"
#    user_data_file_id = proxmox_virtual_environment_file.cloud-init-ctrl-02.id
#  }
#
##  hostpci {
##    # Passthrough iGPU
##    device = "hostpci0"
##    #id     = "0000:00:02"
##    mapping = "iGPU"
##    pcie    = true
##    rombar  = true
##    xvga    = false
##  }
#}
#
#output "ctrl_02_ipv4_address" {
#  depends_on = [proxmox_virtual_environment_vm.k8s-ctrl-02]
#  value      = proxmox_virtual_environment_vm.k8s-ctrl-02.ipv4_addresses[1][0]
#}
#
#resource "local_file" "ctrl-02-ip" {
#  content         = proxmox_virtual_environment_vm.k8s-ctrl-02.ipv4_addresses[1][0]
#  filename        = "output/ctrl-02-ip.txt"
#  file_permission = "0644"
#}
