resource "local_file" "talos_machine_secrets" {
  content = yamlencode({
    cluster    = module.talos.machine_secrets.cluster
    secrets    = module.talos.machine_secrets.secrets
    trustdinfo = module.talos.machine_secrets.trustdinfo
    certs = {
      etcd = {
        crt = module.talos.machine_secrets.certs.etcd.cert
        key = module.talos.machine_secrets.certs.etcd.key
      }
      k8s = {
        crt = module.talos.machine_secrets.certs.k8s.cert
        key = module.talos.machine_secrets.certs.k8s.key
      }
      k8saggregator = {
        crt = module.talos.machine_secrets.certs.k8s_aggregator.cert
        key = module.talos.machine_secrets.certs.k8s_aggregator.key
      }
      k8sserviceaccount = {
        key = module.talos.machine_secrets.certs.k8s_serviceaccount.key
      }
      os = {
        crt = module.talos.machine_secrets.certs.os.cert
        key = module.talos.machine_secrets.certs.os.key
      }
    }
  })
  filename = "output/talos-machine-secrets.yaml"
}

resource "local_file" "talos_machine_configs" {
  for_each        = module.talos.machine_config
  content         = each.value.machine_configuration
  filename        = "output/talos-machine-config-${each.key}.yaml"
  file_permission = "0600"
}

resource "local_file" "talos_config" {
  content         = module.talos.client_configuration.talos_config
  filename        = "output/talos-config.yaml"
  file_permission = "0600"
}

resource "local_file" "kube_config" {
  content         = module.talos.kube_config.kubeconfig_raw
  filename        = "output/kube-config.yaml"
  file_permission = "0600"
}

output "kube_config" {
  value     = module.talos.kube_config.kubeconfig_raw
  sensitive = true
}

output "talos_config" {
  value     = module.talos.client_configuration.talos_config
  sensitive = true
}
