resource "proxmox_virtual_environment_file" "haos_generic_image" {
  provider     = proxmox.euclid
  node_name    = var.euclid.node_name
  content_type = "iso"
  datastore_id = "local"

  source_file {
    path      = "images/haos_ova-12.3.qcow2"
    file_name = "haos_ova-12.3.img"
  }
}
