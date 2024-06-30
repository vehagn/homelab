# Download the Talos image to each distinct Proxmox node
resource "proxmox_virtual_environment_download_file" "talos_nocloud_image" {
  for_each = toset(distinct([for k, v in var.cluster_config.nodes : v.host_node]))

  node_name    = each.key
  content_type = "iso"
  datastore_id = var.talos_image.datastore

  file_name               = "talos-${var.talos_image.version}-nocloud-amd64.img"
  url                     = "${var.talos_image.base_url}/${var.talos_image.version}/nocloud-amd64.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false
}
