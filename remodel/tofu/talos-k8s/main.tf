terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.60.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.5.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_node.endpoint
  insecure = var.proxmox_node.insecure

  api_token = var.proxmox_node.api_token
  ssh {
    agent    = true
    username = var.proxmox_node.username
  }
}

output "talosconfig" {
  value     = data.talos_client_configuration.talosconfig.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = data.talos_cluster_kubeconfig.kubeconfig
  sensitive = true
}

resource "local_file" "talos-config" {
  content         = data.talos_client_configuration.talosconfig.talos_config
  filename        = "output/talos-config.yaml"
  file_permission = "0600"
}

resource "local_file" "kube-config" {
  content         = data.talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  filename        = "output/kube-config.yaml"
  file_permission = "0600"
}