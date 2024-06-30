output "talos_machine_config" {
  value = data.talos_machine_configuration.machine_configuration
}

output "talos_client_configuration" {
  value     = data.talos_client_configuration.talos_config
  sensitive = true
}

output "talos_kube_config" {
  value     = data.talos_cluster_kubeconfig.kubeconfig
  sensitive = true
}
