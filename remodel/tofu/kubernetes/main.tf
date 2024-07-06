module "talos" {
  source = "./talos"

  providers = {
    proxmox = proxmox
  }

  talos_image    = var.talos_image
  cluster_config = var.cluster_config
  cilium = {
    values = file("${path.module}/../../k8s/infra/network/cilium/values.yaml")
    install = file("${path.module}/bootstrap/cilium/install.yaml")
  }
}

module "proxmox_csi_plugin" {
  source = "./bootstrap/proxmox-csi-plugin"

  providers = {
    proxmox    = proxmox
    kubernetes = kubernetes
  }

  proxmox = var.proxmox
}

module "sealed_secrets" {
  source = "./bootstrap/sealed-secrets"

  providers = {
    kubernetes = kubernetes
  }

  // openssl req -x509 -days 365 -nodes -newkey rsa:4096 -keyout sealed-secrets.key -out sealed-secrets.cert -subj "/CN=sealed-secret/O=sealed-secret"
  sealed_secrets_cert = {
    cert = file("${path.module}/bootstrap/sealed-secrets/sealed-secrets.cert")
    key = file("${path.module}/bootstrap/sealed-secrets/sealed-secrets.key")
  }
}

module "volumes" {
  source = "./bootstrap/volumes"

  providers = {
    restapi    = restapi
    kubernetes = kubernetes
  }
  proxmox_api = var.proxmox
  volumes     = var.volumes
}
