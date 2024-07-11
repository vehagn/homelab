module "talos" {
  source = "./talos"

  providers = {
    proxmox = proxmox
  }

  talos_image = {
    version        = "v1.7.5"
    schematic = file("${path.module}/config/talos-image-schematic.yaml")
  }
  cluster_config = var.cluster_config
  cilium = {
    values = file("${path.module}/../../k8s/infra/network/cilium/values.yaml")
    install = file("${path.module}/bootstrap/cilium/install.yaml")
  }
}

module "proxmox_csi_plugin" {
  depends_on = [module.talos]
  source = "./bootstrap/proxmox-csi-plugin"

  providers = {
    proxmox    = proxmox
    kubernetes = kubernetes
  }

  proxmox = var.proxmox
}

module "sealed_secrets" {
  depends_on = [module.talos]
  source = "./bootstrap/sealed-secrets"

  providers = {
    kubernetes = kubernetes
  }

  // openssl req -x509 -days 365 -nodes -newkey rsa:4096 -keyout sealed-secrets.key -out sealed-secrets.cert -subj "/CN=sealed-secret/O=sealed-secret"
  sealed_secrets_cert = {
    cert = file("${path.module}/config/sealed-secrets.cert")
    key = file("${path.module}/config/sealed-secrets.key")
  }
}

module "volumes" {
  depends_on = [module.proxmox_csi_plugin]
  source = "./bootstrap/volumes"

  providers = {
    restapi    = restapi
    kubernetes = kubernetes
  }
  proxmox_api = var.proxmox
  volumes     = var.volumes
}
