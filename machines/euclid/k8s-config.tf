resource "proxmox_virtual_environment_download_file" "debian_12_bookworm" {
  provider     = proxmox.euclid
  node_name    = var.euclid.node_name
  content_type = "iso"
  datastore_id = "local"

  file_name          = "debian-12-generic-amd64-20240201-1644.img"
  url                = "https://cloud.debian.org/images/cloud/bookworm/20240211-1654/debian-12-generic-amd64-20240211-1654.qcow2"
  checksum           = "b679398972ba45a60574d9202c4f97ea647dd3577e857407138b73b71a3c3c039804e40aac2f877f3969676b6c8a1ebdb4f2d67a4efa6301c21e349e37d43ef5"
  checksum_algorithm = "sha512"
}

resource "proxmox_virtual_environment_download_file" "debian_12_bpo" {
  provider     = proxmox.euclid
  node_name    = var.euclid.node_name
  content_type = "iso"
  datastore_id = "local"

  file_name          = "debian-12-backports-generic-amd64-20240429-1732.img"
  url                = "https://cloud.debian.org/images/cloud/bookworm-backports/20240429-1732/debian-12-backports-generic-amd64-20240429-1732.qcow2"
#  checksum           = "b679398972ba45a60574d9202c4f97ea647dd3577e857407138b73b71a3c3c039804e40aac2f877f3969676b6c8a1ebdb4f2d67a4efa6301c21e349e37d43ef5"
#  checksum_algorithm = "sha512"
}

resource "proxmox_virtual_environment_download_file" "ubuntu_jammy_cloud_amd64" {
  provider     = proxmox.euclid
  node_name    = var.euclid.node_name
  content_type = "iso"
  datastore_id = "local"

  file_name          = "jammy-server-cloudimg-amd64.img"
  url                = "https://cloud-images.ubuntu.com/jammy/20240514/jammy-server-cloudimg-amd64.img"
  checksum           = "1718f177dde4c461148ab7dcbdcf2f410c1f5daa694567f6a8bbb239d864b525"
  checksum_algorithm = "sha256"
}

resource "proxmox_virtual_environment_download_file" "ubuntu_mantic-cloud-amd64" {
  provider     = proxmox.euclid
  node_name    = var.euclid.node_name
  content_type = "iso"
  datastore_id = "local"

  file_name          = "mantic-server-cloudimg-amd64.img"
  url                = "https://cloud-images.ubuntu.com/mantic/20240514/mantic-server-cloudimg-amd64.img"
#  checksum           = "1718f177dde4c461148ab7dcbdcf2f410c1f5daa694567f6a8bbb239d864b525"
#  checksum_algorithm = "sha256"
}

resource "proxmox_virtual_environment_download_file" "ubuntu_noble-cloud-amd64" {
  provider     = proxmox.euclid
  node_name    = var.euclid.node_name
  content_type = "iso"
  datastore_id = "local"

  file_name          = "noble-server-cloudimg-amd64.img"
  url                = "https://cloud-images.ubuntu.com/noble/20240505/noble-server-cloudimg-amd64.img"
  #  checksum           = "1718f177dde4c461148ab7dcbdcf2f410c1f5daa694567f6a8bbb239d864b525"
  #  checksum_algorithm = "sha256"
}

#resource "proxmox_virtual_environment_file" "debian_12_backports_image" {
#  provider     = proxmox.euclid
#  node_name    = var.euclid.node_name
#  content_type = "iso"
#  datastore_id = "local"
#
#  source_file {
#    path      = "images/debian-12-backports-generic-amd64-20240429-1732.qcow2"
#    file_name = "debian-12-backports-generic-amd64-20240429-1732.img"
#  }
#}

# Make sure the "Snippets" content type is enabled on the target datastore in Proxmox before applying the configuration below.
# https://github.com/bpg/terraform-provider-proxmox/blob/main/docs/guides/cloud-init.md
resource "proxmox_virtual_environment_file" "cloud-init-ctrl-01" {
  provider     = proxmox.euclid
  node_name    = var.euclid.node_name
  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    data = templatefile("./cloud-init/k8s-control-plane.yaml.tftpl", {
      common-config = templatefile("./cloud-init/k8s-common.yaml.tftpl", {
        hostname    = "k8s-ctrl-01"
        username    = var.vm_user
        password    = var.vm_password
        pub-key     = var.host_pub-key
        k8s-version = var.k8s-version
        kubeadm-cmd = "kubeadm init --skip-phases=addon/kube-proxy"
      })
      username           = var.vm_user
      cilium-cli-version = var.cilium-cli-version
      cilium-cli-cmd     = "HOME=/home/${var.vm_user} KUBECONFIG=/etc/kubernetes/admin.conf cilium install --set kubeProxyReplacement=true"
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
    data = templatefile("./cloud-init/k8s-worker.yaml.tftpl", {
      common-config = templatefile("./cloud-init/k8s-common.yaml.tftpl", {
        hostname    = "k8s-work-01"
        username    = var.vm_user
        password    = var.vm_password
        pub-key     = var.host_pub-key
        k8s-version = var.k8s-version
        kubeadm-cmd = module.kubeadm-join.stdout
      })
    })
    file_name = "cloud-init-k8s-work-01.yaml"
  }
}
