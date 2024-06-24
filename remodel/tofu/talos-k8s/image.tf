resource "proxmox_virtual_environment_download_file" "talos_nocloud_image" {
  for_each = toset(var.host_machines)

  node_name    = each.key
  content_type = "iso"
  datastore_id = var.proxmox_node.image_datastore

  file_name               = "talos-${var.talos_image.version}-nocloud-amd64.img"
  url                     = "${var.talos_image.base_url}/${var.talos_image.version}/nocloud-amd64.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false
}
