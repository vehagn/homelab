module "talos" {
  source = "./talos"

  providers = {
    proxmox = proxmox
  }

  image = {
    version = "v1.9.2"
    update_version = "v1.9.3" # renovate: github-releases=siderolabs/talos
    schematic = file("${path.module}/talos/image/schematic.yaml")
    # Point this to a new schematic file to update the schematic
    update_schematic = file("${path.module}/talos/image/schematic.yaml")
  }

  cilium = {
    values = file("${path.module}/../../k8s/infra/network/cilium/values.yaml")
    install = file("${path.module}/talos/inline-manifests/cilium-install.yaml")
  }

  cluster = {
    name            = "talos"
    # This should point to the vip as below(if nodes on layer 2) or one of the nodes (if nodes not on layer 2)
    # Note: Nodes are not on layer 2 if there is a router between them (even a mesh router)
    #       Not sure how it works if connected to the same router via ethernet (does it act as a switch then???)
    # Ref: https://www.talos.dev/v1.9/talos-guides/network/vip/#requirements
    # Note This is Kubernetes API endpoint. Different from all mentions of Talos endpoints.
    endpoint = "192.168.1.102"
    # Omit this if devices are not connected on layer 2
    vip             = "192.168.1.99"
    gateway         = "192.168.1.1"
    # The version of talos features to use in generated machine configuration. Generally the same as image version.
    # See https://github.com/siderolabs/terraform-provider-talos/blob/main/docs/data-sources/machine_configuration.md
    talos_machine_config_version   = "v1.9.2"
    proxmox_cluster = "homelab"
    kubernetes_version = "1.32.0"  # renovate: github-releases=kubernetes/kubernetes
    base_domain     = "stonegarden.dev"
  }

  nodes = {
    "ctrl-00" = {
      host_node     = "abel"
      machine_type  = "controlplane"
      ip            = "192.168.1.100"
      mac_address   = "BC:24:11:2E:C8:00"
      vm_id         = 800
      cpu           = 8
      ram_dedicated = 28672
      igpu          = true
    }
    "ctrl-01" = {
      host_node     = "euclid"
      machine_type  = "controlplane"
      ip            = "192.168.1.101"
      mac_address   = "BC:24:11:2E:C8:01"
      vm_id         = 801
      cpu           = 4
      ram_dedicated = 20480
      igpu          = true
      #update        = true
    }
    "ctrl-02" = {
      host_node     = "cantor"
      machine_type  = "controlplane"
      ip            = "192.168.1.102"
      mac_address   = "BC:24:11:2E:C8:02"
      vm_id         = 802
      cpu           = 4
      ram_dedicated = 4096
      #update        = true
    }
    #    "work-00" = {
    #      host_node     = "abel"
    #      machine_type  = "worker"
    #      ip            = "192.168.1.110"
    #      mac_address   = "BC:24:11:2E:A8:00"
    #      vm_id         = 810
    #      cpu           = 8
    #      ram_dedicated = 4096
    #    }
  }

}

module "sealed_secrets" {
  depends_on = [module.talos]
  source = "./bootstrap/sealed-secrets"

  providers = {
    kubernetes = kubernetes
  }

  // openssl req -x509 -days 365 -nodes -newkey rsa:4096 -keyout sealed-secrets.key -out sealed-secrets.crt -subj "/CN=sealed-secret/O=sealed-secret"
  cert = {
    cert = file("${path.module}/bootstrap/sealed-secrets/certificate/sealed-secrets.crt")
    key = file("${path.module}/bootstrap/sealed-secrets/certificate/sealed-secrets.key")
  }
}

module "proxmox_csi_plugin" {
  depends_on = [module.talos]
  source = "./bootstrap/proxmox-csi-plugin"

  providers = {
    proxmox    = proxmox
    kubernetes = kubernetes
  }

  proxmox = var.proxmox
}

module "volumes" {
  depends_on = [module.proxmox_csi_plugin]
  source = "./bootstrap/volumes"

  providers = {
    restapi    = restapi
    kubernetes = kubernetes
  }
  proxmox_api = var.proxmox
  volumes = {
    pv-sonarr = {
      node = "cantor"
      size = "4G"
    }
    pv-radarr = {
      node = "cantor"
      size = "4G"
    }
    pv-lidarr = {
      node = "cantor"
      size = "4G"
    }
    pv-prowlarr = {
      node = "euclid"
      size = "1G"
    }
    pv-torrent = {
      node = "euclid"
      size = "1G"
    }
    pv-remark42 = {
      node = "euclid"
      size = "1G"
    }
    pv-authelia-postgres = {
      node = "euclid"
      size = "2G"
    }
    pv-lldap-postgres = {
      node = "euclid"
      size = "2G"
    }
    pv-keycloak-postgres = {
      node = "euclid"
      size = "2G"
    }
    pv-jellyfin = {
      node = "euclid"
      size = "12G"
    }
    pv-netbird-signal = {
      node = "abel"
      size = "512M"
    }
    pv-netbird-management = {
      node = "abel"
      size = "512M"
    }
    pv-plex = {
      node = "abel"
      size = "12G"
    }
    pv-prometheus = {
      node = "abel"
      size = "10G"
    }
  }
}
