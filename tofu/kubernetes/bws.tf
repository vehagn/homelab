data "bitwarden_secret" "secrets" {
  provider   = bitwarden.ro
  for_each   = var.bws_secrets
  id         = each.value
}

resource "bitwarden_secret" "kubeconfig" {
  count      = var.bws_project_id_rw != null ? 1 : 0
  provider   = bitwarden.rw
  key        = "${data.external.git-branch.result.branch}_kubeconfig"
  value      = module.talos.kube_config.kubeconfig_raw
  project_id = var.bws_project_id_rw
  note       = "Kubernetes configuration"
}

resource "bitwarden_secret" "talos_config" {
  count      = var.bws_project_id_rw != null ? 1 : 0
  provider   = bitwarden.rw
  key        = "${data.external.git-branch.result.branch}_talos_config"
  value      = module.talos.client_configuration.talos_config
  project_id = var.bws_project_id_rw
  note       = "Talos configuration"
}

resource "bitwarden_secret" "kube_certificate" {
  count      = var.bws_project_id_rw != null ? 1 : 0
  provider   = bitwarden.rw
  key        = "${data.external.git-branch.result.branch}_kube_certificate"
  value      = file("${path.root}/${var.sealed_secrets_config.certificate_path}")
  project_id = var.bws_project_id_rw
  note       = "Kubernetes certificate"
}

resource "bitwarden_secret" "kube_certificate_key" {
  count      = var.bws_project_id_rw != null ? 1 : 0
  provider   = bitwarden.rw
  key        = "${data.external.git-branch.result.branch}_kube_certificate_key"
  value      = file("${path.root}/${var.sealed_secrets_config.certificate_key_path}")
  project_id = var.bws_project_id_rw
  note       = "Kubernetes certificate key"
}
