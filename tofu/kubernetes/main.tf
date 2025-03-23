module "talos" {
  source = "./talos"

  providers = {
    proxmox = proxmox
  }

  image = var.talos_image
  cluster = var.talos_cluster_config
  nodes = var.talos_nodes
}

module "sealed_secrets" {
  depends_on = [module.talos]
  source = "./bootstrap/sealed-secrets"

  providers = {
    kubernetes = kubernetes
  }

  cert = var.sealed_secrets_config
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

module "volumes" {
  depends_on = [module.proxmox_csi_plugin]
  source = "./bootstrap/volumes"

  providers = {
    restapi    = restapi
    kubernetes = kubernetes
  }

  proxmox_api = var.proxmox
  volumes = var.kubernetes_volumes
}
