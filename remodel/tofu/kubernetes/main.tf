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

  // openssl req -x509 -days 365 -nodes -newkey rsa:4096 -keyout tls.key -out tls.cert -subj "/CN=sealed-secret/O=sealed-secret"
  sealed_secrets_cert = {
    cert = file("${path.module}/tls.cert")
    key = file("${path.module}/tls.key")
  }
}

resource "local_file" "machine_configs" {
  for_each        = module.talos.talos_machine_config
  content         = each.value.machine_configuration
  filename        = "output/talos-machine-config-${each.key}.yaml"
  file_permission = "0600"
}

resource "local_file" "talos_config" {
  content         = module.talos.talos_client_configuration.talos_config
  filename        = "output/talos-config.yaml"
  file_permission = "0600"
}

resource "local_file" "kube_config" {
  content         = module.talos.talos_kube_config.kubeconfig_raw
  filename        = "output/kube-config.yaml"
  file_permission = "0600"
}
