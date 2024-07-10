resource "talos_machine_secrets" "machine_secrets" {
  talos_version = var.cluster_config.talos_version
}

data "talos_client_configuration" "talos_config" {
  cluster_name         = var.cluster_config.cluster_name
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoints            = [for k, v in var.cluster_config.nodes : v.ip if v.machine_type == "controlplane"]
}

data "talos_machine_configuration" "machine_configuration" {
  for_each         = var.cluster_config.nodes
  cluster_name     = var.cluster_config.cluster_name
  cluster_endpoint = var.cluster_config.endpoint
  machine_type     = each.value.machine_type
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
  talos_version    = var.cluster_config.talos_version
  config_patches   = each.value.machine_type == "controlplane" ? [
    templatefile("${path.module}/machine-config/control-plane.yaml.tftpl", {
      hostname       = each.key
      cluster_name   = var.cluster_config.proxmox_cluster
      node_name      = each.value.host_node
      cilium_values  = var.cilium.values
      cilium_install = var.cilium.install
    })
  ] : [
    templatefile("${path.module}/machine-config/worker.yaml.tftpl", {
      hostname     = each.key
      cluster_name = var.cluster_config.proxmox_cluster
      node_name    = each.value.host_node
    })
  ]
}

resource "talos_machine_configuration_apply" "talos_config_apply" {
  depends_on = [proxmox_virtual_environment_vm.talos_vm]
  for_each                    = var.cluster_config.nodes
  node                        = each.value.ip
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machine_configuration[each.key].machine_configuration
  lifecycle {
    # re-run config apply if vm changes
    replace_triggered_by = [proxmox_virtual_environment_vm.talos_vm[each.key]]
  }
}

resource "talos_machine_bootstrap" "talos_bootstrap" {
  depends_on = [talos_machine_configuration_apply.talos_config_apply]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = [for k, v in var.cluster_config.nodes : v.ip if v.machine_type == "controlplane" && !v.update][0]
}

data "talos_cluster_health" "health" {
  depends_on = [talos_machine_bootstrap.talos_bootstrap]
  client_configuration = data.talos_client_configuration.talos_config.client_configuration
  control_plane_nodes  = [for k, v in var.cluster_config.nodes : v.ip if v.machine_type == "controlplane"]
  worker_nodes         = [for k, v in var.cluster_config.nodes : v.ip if v.machine_type == "worker"]
  endpoints            = data.talos_client_configuration.talos_config.endpoints
  timeouts = {
    read = "10m"
  }
}

data "talos_cluster_kubeconfig" "kubeconfig" {
  #  depends_on = [talos_machine_bootstrap.talos_bootstrap]
  depends_on = [talos_machine_bootstrap.talos_bootstrap, data.talos_cluster_health.health]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = [for k, v in var.cluster_config.nodes : v.ip if v.machine_type == "controlplane" && !v.update][0]
  timeouts = {
    read = "1m"
  }
}
