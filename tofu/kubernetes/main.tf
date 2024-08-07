module "talos" {
  source = "./talos"

  providers = {
    proxmox = proxmox
  }

  image = {
    version        = "v1.7.5"
    schematic = file("${path.module}/talos/image/schematic.yaml")
  }

  cilium = {
    values = file("${path.module}/../../k8s/infra/network/cilium/values.yaml")
    install = file("${path.module}/talos/inline-manifests/cilium-install.yaml")
  }

  cluster = {
    name            = "talos"
    endpoint        = "192.168.1.100"
    gateway         = "192.168.1.1"
    talos_version   = "v1.7"
    proxmox_cluster = "homelab"
  }

  nodes = {
    "ctrl-00" = {
      host_node     = "abel"
      machine_type  = "controlplane"
      ip            = "192.168.1.100"
      mac_address   = "BC:24:11:2E:C8:00"
      vm_id         = 8000
      cpu           = 8
      ram_dedicated = 20480
      igpu          = true
    }
    "ctrl-01" = {
      host_node     = "euclid"
      machine_type  = "controlplane"
      ip            = "192.168.1.101"
      mac_address   = "BC:24:11:2E:C8:01"
      vm_id         = 8001
      cpu           = 4
      ram_dedicated = 20480
      igpu          = true
    }
    "ctrl-02" = {
      host_node     = "cantor"
      machine_type  = "controlplane"
      ip            = "192.168.1.102"
      mac_address   = "BC:24:11:2E:C8:02"
      vm_id         = 8002
      cpu           = 4
      ram_dedicated = 4096
    }
  }

}

module "sealed_secrets" {
  depends_on = [module.talos]
  source = "./bootstrap/sealed-secrets"

  providers = {
    kubernetes = kubernetes
  }

  // openssl req -x509 -days 365 -nodes -newkey rsa:4096 -keyout sealed-secrets.key -out sealed-secrets.cert -subj "/CN=sealed-secret/O=sealed-secret"
  cert = {
    cert = file("${path.module}/bootstrap/sealed-secrets/certificate/sealed-secrets.cert")
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
    pv-sonarr-config = {
      node = "cantor"
      size = "4G"
    }
    pv-radarr-config = {
      node = "cantor"
      size = "4G"
    }
    pv-lidarr-config = {
      node = "cantor"
      size = "4G"
    }
    pv-prowlarr-config = {
      node = "euclid"
      size = "1G"
    }
    pv-torrent-config = {
      node = "euclid"
      size = "1G"
    }
    pv-remark42 = {
      node = "euclid"
      size = "1G"
    }
    pv-keycloak-db = {
      node = "euclid"
      size = "2G"
    }
    pv-jellyfin-config = {
      node = "euclid"
      size = "12G"
    }
    pv-netbird-signal = {
      node = "abel"
      size = "1G"
    }
    pv-netbird-management = {
      node = "abel"
      size = "1G"
    }
    pv-plex-config = {
      node = "abel"
      size = "12G"
    }
    pv-prometheus = {
      node = "abel"
      size = "10G"
    }
  }
}
