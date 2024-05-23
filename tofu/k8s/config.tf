resource "talos_machine_secrets" "machine_secrets" {
  talos_version = "v1.7"
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
  talos_version    = "v1.7"
  config_patches   = [
    templatefile("talos/control-plane.yaml.tftpl", {
      hostname = each.key
    })
  ]
}


resource "proxmox_virtual_environment_file" "controlplane-config" {
  provider = proxmox.abel
  for_each = var.node_data.controlplanes

  node_name    = each.value.host_node
  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    data      = data.talos_machine_configuration.control-plane[each.key].machine_configuration
    file_name = "talos-${each.key}.cloud-config.yaml"
  }
}

resource "talos_machine_configuration_apply" "ctrl_config_apply" {
  depends_on                  = [proxmox_virtual_environment_vm.controlplane]
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
  talos_version    = "v1.7"
  config_patches   = [
    templatefile("talos/worker.yaml.tftpl", {
      hostname = each.key
    })
  ]
}

resource "proxmox_virtual_environment_file" "worker-config" {
  provider = proxmox.abel
  for_each = var.node_data.workers

  node_name    = each.value.host_node
  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    data      = data.talos_machine_configuration.worker[each.key].machine_configuration
    file_name = "talos-${each.key}.cloud-config.yaml"
  }
}

resource "talos_machine_configuration_apply" "worker_config_apply" {
  depends_on                  = [proxmox_virtual_environment_vm.workers]
  for_each                    = var.node_data.workers
  node                        = each.value.ip
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker[each.key].machine_configuration
  config_patches   = [
    templatefile("talos/worker.yaml.tftpl", {
      hostname = each.key
    })
  ]
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on           = [talos_machine_configuration_apply.ctrl_config_apply]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = [for k, v in var.node_data.controlplanes : v.ip][0]
}

data "talos_cluster_health" "health" {
  depends_on           = [talos_machine_configuration_apply.ctrl_config_apply]
  client_configuration = data.talos_client_configuration.talosconfig.client_configuration
  control_plane_nodes  = [for k, v in var.node_data.controlplanes : v.ip]
  worker_nodes         = [for k, v in var.node_data.workers : v.ip]
  endpoints            = data.talos_client_configuration.talosconfig.endpoints
  timeouts = {
    read = "10m"
  }
}

data "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on           = [talos_machine_bootstrap.bootstrap, data.talos_cluster_health.health]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = [for k, v in var.node_data.controlplanes : v.ip][0]
}

output "talosconfig" {
  value     = data.talos_client_configuration.talosconfig.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = data.talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  sensitive = true
}

resource "local_file" "taloc-client-config" {
  content         = data.talos_client_configuration.talosconfig.talos_config
  filename        = "output/talos-config.yaml"
  file_permission = "0600"
}

resource "local_file" "kube-config" {
  content         = data.talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  filename        = "output/kube-config.yaml"
  file_permission = "0600"
}
