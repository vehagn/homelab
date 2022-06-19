terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    helm       = {
      source  = "hashicorp/helm"
      version = ">= 2.5.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

#resource "helm_release" "cilium" {
#  name = "cilium"
#
#  repository = "https://helm.cilium.io"
#  chart      = "cilium"
#  namespace  = "kube-system"
#  version    = "1.11.5"
#}

resource "kubernetes_namespace" "traefik" {
  metadata {
    name = "traefik"
  }
}

resource "helm_release" "traefik" {
  name = "traefik"

  repository = "https://helm.traefik.io/traefik"
  chart      = "traefik"
  namespace  = "traefik"
  version    = "10.20.0"

}

resource "kubernetes_service" "traefik" {
  metadata {
    name      = "traefik"
    namespace = kubernetes_namespace.traefik.metadata.0.name
  }
  spec {
    selector = {
      # Standard Helm chart label to locate pods
      "app.kubernetes.io/name" = helm_release.traefik.name
    }

    type = "LoadBalancer"
    port {
      protocol    = "TCP"
      port        = 80    # External exposed port to reach container
      target_port = 9000  # Internal exposed port of container
    }
  }
}

resource "kubernetes_namespace" "test" {
  metadata {
    name = "nginx"
  }
}

resource "kubernetes_deployment" "test" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.test.metadata.0.name
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "MyTestApp"
      }
    }
    template {
      metadata {
        labels = {
          app = "MyTestApp"
        }
      }
      spec {
        container {
          image = "nginx"
          name  = "nginx-container"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "test" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.test.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.test.spec.0.template.0.metadata.0.labels.app
    }

    type = "LoadBalancer"
    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }
  }
}
