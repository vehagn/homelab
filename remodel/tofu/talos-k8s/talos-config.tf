resource "talos_machine_secrets" "machine_secrets" {
  talos_version = var.cluster.talos_version
}

data "talos_client_configuration" "talosconfig" {
  cluster_name         = var.cluster.name
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoints            = [for k, v in var.node_data.controlplanes : v.ip]
}

data "talos_machine_configuration" "control-plane" {
  for_each         = var.node_data.controlplanes
  cluster_name     = var.cluster.name
  cluster_endpoint = var.cluster.endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
  talos_version    = var.cluster.talos_version
  config_patches = [
    templatefile("${path.module}/machine-config/control-plane.yaml.tftpl", {
      hostname = each.key
      inlineManifests = indent(2,
        yamlencode(
          {
            inlineManifests : [
              {
                name : "cilium-bootstrap",
                contents : file("${path.module}/bootstrap/cilium-install.yaml")
              }
            ]
          }))
    })
  ]
}

resource "talos_machine_configuration_apply" "ctrl_config_apply" {
  depends_on = [proxmox_virtual_environment_vm.controlplane]
  for_each                    = var.node_data.controlplanes
  node                        = each.value.ip
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.control-plane[each.key].machine_configuration
}

data "talos_machine_configuration" "worker" {
  for_each         = var.node_data.workers
  cluster_name     = var.cluster.name
  cluster_endpoint = var.cluster.endpoint
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
  talos_version    = var.cluster.talos_version
  config_patches = [
    templatefile("${path.module}/machine-config/worker.yaml.tftpl", {
      hostname = each.key
    })
  ]
}

resource "talos_machine_configuration_apply" "worker_config_apply" {
  depends_on = [proxmox_virtual_environment_vm.workers]
  for_each                    = var.node_data.workers
  node                        = each.value.ip
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker[each.key].machine_configuration
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on = [talos_machine_configuration_apply.ctrl_config_apply]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = [for k, v in var.node_data.controlplanes : v.ip][0]
}

data "talos_cluster_health" "health" {
  depends_on = [talos_machine_configuration_apply.ctrl_config_apply]
  client_configuration = data.talos_client_configuration.talosconfig.client_configuration
  control_plane_nodes  = [for k, v in var.node_data.controlplanes : v.ip]
  worker_nodes         = [for k, v in var.node_data.workers : v.ip]
  endpoints            = data.talos_client_configuration.talosconfig.endpoints
  timeouts = {
    read = "10m"
  }
}

data "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on = [talos_machine_bootstrap.bootstrap, data.talos_cluster_health.health]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = [for k, v in var.node_data.controlplanes : v.ip][0]
}
