resource "talos_machine_secrets" "machine_secrets" {
  talos_version = var.cluster.talos_version
}

data "talos_client_configuration" "talos_config" {
  cluster_name         = var.cluster.name
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoints            = [for k, v in var.talos_nodes.nodes : v.ip if v.machine_type == "controlplane"]
}

#data "template_file" "cilium-install" {
#  template = file("${path.module}/bootstrap/cilium-install.yaml")
#  vars = {
#    ciliumValues = file("${path.module}/../../k8s/infra/network/cilium/values.yaml")
#  }
#}

data "talos_machine_configuration" "machine_configuration" {
  for_each         = var.talos_nodes.nodes
  cluster_name     = var.cluster.name
  cluster_endpoint = var.cluster.endpoint
  machine_type     = each.value.machine_type
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
  talos_version    = var.cluster.talos_version
  config_patches   = each.value.machine_type == "controlplane" ? [
    templatefile("${path.module}/machine-config/control-plane.yaml.tftpl", {
      hostname = each.key
      ciliumValues = file("${path.module}/../../k8s/infra/network/cilium/values.yaml")
      ciliumInstall = file("${path.module}/bootstrap/cilium-install.yaml")
    })
  ] : [
    templatefile("${path.module}/machine-config/worker.yaml.tftpl", {
      hostname = each.key
    })
  ]
}

resource "talos_machine_configuration_apply" "ctrl_config_apply" {
  depends_on = [proxmox_virtual_environment_vm.controlplane]
  for_each                    = var.talos_nodes.nodes
  node                        = each.value.ip
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machine_configuration[each.key].machine_configuration
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on = [talos_machine_configuration_apply.ctrl_config_apply]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = [for k, v in var.talos_nodes.nodes : v.ip if v.machine_type == "controlplane"][0]
}

data "talos_cluster_health" "health" {
  depends_on = [talos_machine_configuration_apply.ctrl_config_apply]
  client_configuration = data.talos_client_configuration.talos_config.client_configuration
  control_plane_nodes  = [for k, v in var.talos_nodes.nodes : v.ip if v.machine_type == "controlplane"]
  worker_nodes         = [for k, v in var.talos_nodes.nodes : v.ip if v.machine_type == "worker"]
  endpoints            = data.talos_client_configuration.talos_config.endpoints
  timeouts = {
    read = "10m"
  }
}

data "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on = [talos_machine_bootstrap.bootstrap, data.talos_cluster_health.health]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = [for k, v in var.talos_nodes.nodes : v.ip if v.machine_type == "controlplane"][0]
}
