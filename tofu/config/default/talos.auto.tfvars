talos_image = {
  version = "v1.9.2"
  update_version = "v1.9.3" # renovate: github-releases=siderolabs/talos
  schematic = "talos/image/schematic.yaml"
  # Point this to a new schematic file to update the schematic
  update_schematic = "talos/image/schematic.yaml"
}

# TODO: Change after merge
cluster_config = {
  name            = "talos"
  endpoint        = "192.168.1.102"
  gateway         = "192.168.1.1"
  talos_version   = "v1.8"
  proxmox_cluster = "homelab"
}

cluster_nodes = {
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

cluster_volumes = {
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

create_sealed_secret_certificates = true
