locals {
  schematic_id = jsondecode(data.http.schematic_id.response_body)["id"]
  update_schematic = coalesce(var.talos_image.update_schematic, var.talos_image.schematic)
  update_version = coalesce(var.talos_image.update_version, var.talos_image.version)
  update_schematic_id = jsondecode(data.http.updated_schematic_id.response_body)["id"]
}

data "http" "schematic_id" {
  url          = "${var.talos_image.factory_url}/schematics"
  method       = "POST"
  request_body = var.talos_image.schematic
}

data "http" "updated_schematic_id" {
  url          = "${var.talos_image.factory_url}/schematics"
  method       = "POST"
  request_body = local.update_schematic
}

resource "proxmox_virtual_environment_download_file" "talos_image" {
  for_each = toset(distinct([for k, v in var.cluster_config.nodes : v.host_node]))

  node_name    = each.key
  content_type = "iso"
  datastore_id = var.talos_image.proxmox_datastore

  file_name               = "talos-${local.schematic_id}-${var.talos_image.version}-${var.talos_image.platform}-${var.talos_image.arch}.img"
  url                     = "${var.talos_image.factory_url}/image/${local.schematic_id}/${var.talos_image.version}/${var.talos_image.platform}-${var.talos_image.arch}.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false
}

resource "proxmox_virtual_environment_download_file" "updated_talos_image" {
  for_each = toset(distinct([for k, v in var.cluster_config.nodes : v.host_node if v.update]))

  node_name    = each.key
  content_type = "iso"
  datastore_id = var.talos_image.proxmox_datastore

  file_name               = "talos-update-${local.update_schematic_id}-${local.update_version}-${var.talos_image.platform}-${var.talos_image.arch}.img"
  url                     = "${var.talos_image.factory_url}/image/${local.update_schematic_id}/${var.talos_image.update_version}/${var.talos_image.platform}-${var.talos_image.arch}.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false
}
