resource "kubernetes_namespace" "sealed-secrets" {
  metadata {
    name = "sealed-secrets"
  }
}

resource "kubernetes_secret" "sealed-secrets-key" {
  depends_on = [kubernetes_namespace.sealed-secrets]
  type = "kubernetes.io/tls"

  metadata {
    name      = "sealed-secrets-bootstrap-key"
    namespace = "sealed-secrets"
    labels = {
      "sealedsecrets.bitnami.com/sealed-secrets-key" = "active"
    }
  }

  data = {
    "tls.crt" = file("${path.root}/${var.cert.certificate_path}")
    "tls.key" = file("${path.root}/${var.cert.certificate_key_path}")
  }
}
