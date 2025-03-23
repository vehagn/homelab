talos_nodes = {
  "ctrl-00" = {
    host_node     = "abel"
    machine_type  = "controlplane"
    ip = "192.168.1.100"
    #dns           = ["1.1.1.1", "8.8.8.8"] # Optional Value.
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
