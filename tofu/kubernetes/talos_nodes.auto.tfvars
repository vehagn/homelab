talos_nodes = {
  "ctrl-00" = {
    host_node     = "pve01"
    machine_type  = "controlplane"
    ip            = "192.168.71.51"
    mac_address   = "BC:24:11:DE:49:29"
    vm_id         = 800
    cpu           = 3
    ram_dedicated = 8192
    igpu          = true
  }
  "ctrl-01" = {
    host_node     = "pve02"
    machine_type  = "controlplane"
    ip            = "192.168.71.52"
    mac_address   = "BC:24:11:83:29:D1"
    vm_id         = 801
    cpu           = 3
    ram_dedicated = 16384
    igpu          = true
    #update        = true
  }
  "ctrl-02" = {
    host_node     = "pve03"
    machine_type  = "controlplane"
    ip            = "192.168.71.53"
    mac_address   = "BC:24:11:C7:12:F2"
    vm_id         = 802
    cpu           = 3
    ram_dedicated = 20480
    #update        = true
  }
  #    "work-00" = {
  #      host_node     = "abel"
  #      machine_type  = "worker"
  #      ip            = "192.168.1.110"
  #      dns           = ["1.1.1.1", "8.8.8.8"] # Optional Value.
  #      mac_address   = "BC:24:11:2E:A8:00"
  #      vm_id         = 810
  #      cpu           = 8
  #      ram_dedicated = 4096
  #    }
}
