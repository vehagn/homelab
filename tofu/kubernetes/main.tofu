module "talos" {
  source = "./talos"

  providers = {
    proxmox = proxmox
  }

  image   = var.talos_image
  cluster = var.talos_cluster_config
  nodes   = var.talos_nodes
}

module "sealed_secrets" {
  depends_on = [module.talos]
  source     = "./bootstrap/sealed-secrets"

  providers = {
    kubernetes = kubernetes
  }

  cert = var.sealed_secrets_config
}

module "proxmox_csi_plugin" {
  depends_on = [module.talos]
  source     = "./bootstrap/proxmox-csi-plugin"

  providers = {
    proxmox    = proxmox
    kubernetes = kubernetes
  }

  proxmox = var.proxmox
}

module "volumes" {
  depends_on = [module.proxmox_csi_plugin]
  source     = "./bootstrap/volumes"

  providers = {
    restapi    = restapi
    kubernetes = kubernetes
  }

  proxmox_api = var.proxmox
  volumes     = var.kubernetes_volumes
}

module "infisical_secrets" {
  # Conditionally create infisical module based on where var.infisical is set in infisical.auto.tfvars
  count  = (var.infisical_project_id != null && var.infisical_client_id != null) ? 1 : 0

  source = "./infisical"

  infisical_domain             = var.infisical_domain
  infisical_client_id          = var.infisical_client_id
  infisical_project_id         = var.infisical_project_id
  infisical_rw_secrets_path    = var.infisical_rw_secrets_path
  infisical_branch_env_mapping = var.infisical_branch_env_mapping
  infisical_client_secret      = var.infisical_client_secret

  secrets_to_create = {
    # Create map entries only for non-null values
    for k, v in {
      "kubeconfig"           = module.talos.kube_config.kubeconfig_raw
      "talos_config"         = module.talos.client_configuration.talos_config
      "kube_certificate"     = file("${path.root}/${var.sealed_secrets_config.certificate_path}")
      "kube_certificate_key" = file("${path.root}/${var.sealed_secrets_config.certificate_key_path}")
    } : k => v if v != null
  }
}
