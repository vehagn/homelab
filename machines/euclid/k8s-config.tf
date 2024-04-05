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
