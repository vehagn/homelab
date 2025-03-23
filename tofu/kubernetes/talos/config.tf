resource "talos_machine_secrets" "this" {
  talos_version = var.cluster.talos_machine_config_version
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster.name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [for k, v in var.nodes : v.ip]
  # Don't use vip in talosconfig endpoints
  # ref - https://www.talos.dev/v1.9/talos-guides/network/vip/#caveats
  endpoints            = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"]
}

resource "terraform_data" "cilium_bootstrap_inline_manifests" {
  input = [
    {
      name     = "cilium-bootstrap"
      contents = file("${path.root}/${var.cluster.cilium.bootstrap_manifest_path}")
    },
    {
      name     = "cilium-values"
      contents = yamlencode({
        apiVersion = "v1"
        kind       = "ConfigMap"
        metadata = {
          name      = "cilium-values"
          namespace = "kube-system"
        }
        data = {
          "values.yaml" = file("${path.root}/${var.cluster.cilium.values_file_path}")
        }
      })
    }
  ]
}

data "talos_machine_configuration" "this" {
  for_each        = var.nodes
  cluster_name    = var.cluster.name
  # This is the Kubernetes API Server endpoint.
  # ref - https://www.talos.dev/v1.9/introduction/prodnotes/#decide-the-kubernetes-endpoint
  cluster_endpoint = "https://${var.cluster.endpoint}:6443"
  # @formatter:off
  talos_version = var.cluster.talos_machine_config_version != null ? var.cluster.talos_machine_config_version : (each.value.update == true ? var.image.update_version : var.image.version)
  # @formatter:on
  machine_type    = each.value.machine_type
  machine_secrets = talos_machine_secrets.this.machine_secrets
  config_patches = [
    templatefile("${path.module}/machine-config/common.yaml.tftpl", {
      node_name    = each.value.host_node
      cluster_name = var.cluster.proxmox_cluster
      hostname     = each.key
      ip           = each.value.ip
      mac_address = lower(each.value.mac_address)
      gateway      = var.cluster.gateway
      subnet_mask  = var.cluster.subnet_mask
      vip          = var.cluster.vip
    }), each.value.machine_type == "controlplane" ?
      templatefile("${path.module}/machine-config/control-plane.yaml.tftpl", {
        kubelet = var.cluster.kubelet
        extra_manifests = jsonencode(var.cluster.extra_manifests)
        api_server = var.cluster.api_server
        inline_manifests = jsonencode(terraform_data.cilium_bootstrap_inline_manifests.output)
      }) : ""
  ]
}

resource "talos_machine_configuration_apply" "this" {
  depends_on = [proxmox_virtual_environment_vm.this]
  for_each                    = var.nodes
  node                        = each.value.ip
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this[each.key].machine_configuration
  lifecycle {
    # re-run config apply if vm changes
    replace_triggered_by = [proxmox_virtual_environment_vm.this[each.key]]
  }
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.this]
  # Bootstrap with the first node. VIP not yet available at this stage, so cant use var.cluster.endpoint as it may be set to VIP
  # ref - https://www.talos.dev/v1.9/talos-guides/network/vip/#caveats
  node                 = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"][0]
  client_configuration = talos_machine_secrets.this.client_configuration
}

data "talos_cluster_health" "this" {
  depends_on = [
    talos_machine_configuration_apply.this,
    talos_machine_bootstrap.this
  ]
  skip_kubernetes_checks = false
  client_configuration   = data.talos_client_configuration.this.client_configuration
  control_plane_nodes    = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"]
  worker_nodes           = [for k, v in var.nodes : v.ip if v.machine_type == "worker"]
  endpoints              = data.talos_client_configuration.this.endpoints
  timeouts = {
    read = "10m"
  }
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this,
    data.talos_cluster_health.this
  ]
  # If using VIP, it should be up by now, but to be safer retrive from one of the nodes
  # As mentioned don't use talosctl on vip
  # ref - https://www.talos.dev/v1.9/talos-guides/network/vip/#caveats
  # In kubeconfig endpoint will be polulated by cluster_endpoint from machine-config
  node                 = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"][0]
  client_configuration = talos_machine_secrets.this.client_configuration
  timeouts = {
    read = "1m"
  }
}
