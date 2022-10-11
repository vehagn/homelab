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

## Create namespace for Traefik
resource "kubernetes_namespace" "traefik" {
  metadata {
    name = "traefik-system"
  }
}

## Create StorageClass for local volumes
resource "kubernetes_storage_class" "cert-storage" {
  metadata {
    name = "cert-storage"
  }
  storage_provisioner = "kubernetes.io/no-provisioner"
  volume_binding_mode = "WaitForFirstConsumer"
}

## Create PersistentVolume for Traefik certs
resource "kubernetes_persistent_volume" "traefik-cert-pv" {
  metadata {
    name = "traefik-cert-pv"
  }
  spec {
    capacity                         = {
      storage = "128Mi"
    }
    volume_mode                      = "Filesystem"
    access_modes                     = ["ReadWriteOnce"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name               = "cert-storage"
    persistent_volume_source {
      local {
        path = "/mnt/sdb1/terrakube/certs"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = ["ratatoskr"]
          }
        }
      }
    }
  }
}

## Install Traefik
resource "helm_release" "traefik" {
  name = "traefik"

  repository = "https://helm.traefik.io/traefik"
  chart      = "traefik"
  namespace  = kubernetes_namespace.traefik.metadata.0.name
  #version    = "10.30.1"

  values = [file("helm/traefik-values.yaml")]
}

# --- whoami
#resource "kubernetes_namespace" "whoami" {
#  metadata {
#    name = "whoami"
#  }
#}
#
#resource "kubernetes_service" "whoami" {
#  metadata {
#    name = "whoami"
#    namespace = kubernetes_namespace.whoami.metadata.0.name
#  }
#  spec {
#    selector = {
#      app = kubernetes_deployment.whoami.spec.0.template.0.metadata.0.labels.app
#    }
#
#    type = "LoadBalancer"
#    port {
#      protocol = "TCP"
#      name = "web"
#      port = 80
#    }
#  }
#}
#
#resource "kubernetes_deployment" "whoami" {
#  metadata {
#    name = "whoami"
#    namespace = kubernetes_namespace.whoami.metadata.0.name
#  }
#  spec {
#    replicas = "2"
#    selector {
#      match_labels = {
#        app = "whoami"
#      }
#    }
#    template {
#      metadata {
#        labels = {
#          app = "whoami"
#        }
#      }
#      spec {
#        container {
#          name = "whoami"
#          image = "traefik/whoami"
#          port {
#            name = "web"
#            container_port = 80
#          }
#        }
#      }
#    }
#  }
#}
#
#resource "helm_release" "whoami" {
#  name       = "whoami"
#  repository = "https://charts.itscontained.io"
#  chart      = "raw"
#  version    = "0.2.5"
#
#  values = [file("helm/whoami-values.yaml")]
#}

//resource "kubernetes_namespace" "test" {
//  metadata {
//    name = "nginx"
//  }
//}
//
//resource "kubernetes_service" "test" {
//  metadata {
//    name      = "nginx"
//    namespace = kubernetes_namespace.test.metadata.0.name
//  }
//  spec {
//    selector = {
//      app = kubernetes_deployment.test.spec.0.template.0.metadata.0.labels.app
//    }
//
//    type = "LoadBalancer"
//    port {
//      protocol    = "TCP"
//      port        = 80
//      target_port = 80
//    }
//  }
//}
//
//resource "kubernetes_deployment" "test" {
//  metadata {
//    name      = "nginx"
//    namespace = kubernetes_namespace.test.metadata.0.name
//  }
//  spec {
//    replicas = 2
//    selector {
//      match_labels = {
//        app = "MyTestApp"
//      }
//    }
//    template {
//      metadata {
//        labels = {
//          app = "MyTestApp"
//        }
//      }
//      spec {
//        container {
//          image = "nginx"
//          name  = "nginx-container"
//          port {
//            container_port = 80
//          }
//        }
//      }
//    }
//  }
//}

