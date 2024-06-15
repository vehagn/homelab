locals {
  talos = {
    version = "v1.7.4" # renovate: github-releases=siderolabs/talos
    checksum = "26e23f1bf44eecb0232d0aa221223b44f4e40806b7d12cf1a72626927da9a8a4"
  }
}

resource "proxmox_virtual_environment_file" "talos_nocloud_image" {
  provider = proxmox.abel
  for_each = toset(var.host_machines)

  node_name    = each.key
  content_type = "iso"
  datastore_id = "local"

  source_file {
    path      = "images/talos-${local.talos.version}-nocloud-amd64.raw"
    file_name = "talos-${local.talos.version}-nocloud-amd64.img"
  }
}