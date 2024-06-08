resource "talos_machine_secrets" "this" {}

####data "talos_machine_configuration" "this" {
####  cluster_name     = "talos"
####  cluster_endpoint = "https://cluster.local:6443"
####  machine_secrets  = talos_machine_secrets.this.machine_secrets
####  machine_type     = "controlplane"
####}
####
####data "talos_client_configuration" "this" {
####  client_configuration = talos_machine_secrets.this.client_configuration
####  cluster_name         = "talos"
####  nodes                = [var.k8s-ctrl-00.ip]
####}
####
####resource "talos_machine_configuration_apply" "this" {
####  client_configuration        = talos_machine_secrets.this.client_configuration
####  machine_configuration_input = data.talos_machine_configuration.this.machine_configuration
####  node                        = var.k8s-ctrl-00.ip
####}
####
####resource "talos_machine_bootstrap" "this" {
####  depends_on           = [talos_machine_configuration_apply.this]
####  client_configuration = talos_machine_secrets.this.client_configuration
####  node                 = var.k8s-ctrl-00.ip
####}

resource "talos_machine_secrets" "machine_secrets" {}

data "talos_client_configuration" "talosconfig" {
  cluster_name         = var.cluster.name
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoints            = [var.k8s-ctrl-00.ip]
}

data "talos_machine_configuration" "k8s-ctrl-00" {
  cluster_name     = var.cluster.name
  cluster_endpoint = "https://${var.k8s-ctrl-00.ip}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
  config_patches   = [templatefile("talos/k8s-ctrl-00.tftpl", {})]
}

resource "talos_machine_configuration_apply" "k8s-ctrl-00_config_apply" {
#  depends_on                  = [proxmox_virtual_environment_vm.k8s-ctrl-00]
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.k8s-ctrl-00.machine_configuration
  count                       = 1
  node                        = var.k8s-ctrl-00.ip
}


##data "talos_machine_configuration" "machineconfig_worker" {
##  cluster_name     = var.cluster_name
##  cluster_endpoint = "https://${var.talos_cp_01_ip_addr}:6443"
##  machine_type     = "worker"
##  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
##  config_patches   = [ templatefile("cluster/talos/machineconfig-worker.tftpl", {}) ]
##}
##
##resource "talos_machine_configuration_apply" "worker_config_apply" {
##  depends_on                  = [ proxmox_virtual_environment_vm.talos_worker_01 ]
##  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
##  machine_configuration_input = data.talos_machine_configuration.machineconfig_worker.machine_configuration
##  count                       = 1
##  node                        = var.talos_worker_01_ip_addr
##}


resource "talos_machine_bootstrap" "bootstrap" {
  depends_on           = [talos_machine_configuration_apply.k8s-ctrl-00_config_apply]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = var.k8s-ctrl-00.ip
}

#data "talos_cluster_health" "health" {
#  #depends_on            = [ talos_machine_configuration_apply.k8s-ctrl-01_config_apply, talos_machine_configuration_apply.worker_config_apply ]
#  depends_on           = [talos_machine_configuration_apply.k8s-ctrl-00_config_apply]
#  client_configuration = data.talos_client_configuration.talosconfig.client_configuration
#  control_plane_nodes  = [var.k8s-ctrl-00.ip]
#  worker_nodes = []
#  #worker_nodes          = [ var.talos_worker_01_ip_addr ]
#  endpoints            = data.talos_client_configuration.talosconfig.endpoints
#  timeouts = {
#    read = "10m"
#  }
#}

data "talos_cluster_kubeconfig" "kubeconfig" {
  #  depends_on           = [talos_machine_bootstrap.bootstrap, data.talos_cluster_health.health]
  depends_on           = [talos_machine_bootstrap.bootstrap]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = var.k8s-ctrl-00.ip
  timeouts = {
    read = "60s"
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

resource "local_file" "taloc-client-config" {
  content  = data.talos_client_configuration.talosconfig.talos_config
  filename = "output/talos-config.yaml"
  #  file_permission = "0600"
}

resource "local_file" "talos-machine-config" {
  content  = data.talos_machine_configuration.k8s-ctrl-00.machine_configuration
  filename = "output/talos-${var.k8s-ctrl-00.hostname}.yaml"
  #  file_permission = "0600"
}

resource "local_file" "kube-config" {
  content  = data.talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  filename = "output/kube-config.yaml"
  #  file_permission = "0600"
}
