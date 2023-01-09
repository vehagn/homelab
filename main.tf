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

### Create namespace for Traefik
#resource "kubernetes_namespace" "traefik" {
#  metadata {
#    name = "traefik-system"
#  }
#}

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
        path = "/disk/etc/traefik/certs"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = ["gauss"]
          }
        }
      }
    }
  }
}

### Install Traefik
#resource "helm_release" "traefik" {
#  name = "traefik"
#
#  repository = "https://helm.traefik.io/traefik"
#  chart      = "traefik"
#  namespace  = kubernetes_namespace.traefik.metadata.0.name
#  #version    = "10.30.1"
#
#  values = [file("helm/traefik-values.yaml")]
#}