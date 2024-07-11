locals {
  version = var.talos_image.version
  schematic = var.talos_image.schematic
  schematic_id = jsondecode(data.http.schematic_id.response_body)["id"]
  url = "${var.talos_image.factory_url}/image/${local.schematic_id}/${local.version}/${var.talos_image.platform}-${var.talos_image.arch}.raw.gz"
  image_id = "${local.schematic_id}_${local.version}"

  update_version = coalesce(var.talos_image.update_version, var.talos_image.version)
  update_schematic = coalesce(var.talos_image.update_schematic, var.talos_image.schematic)
  update_schematic_id = jsondecode(data.http.updated_schematic_id.response_body)["id"]
  update_url = "${var.talos_image.factory_url}/image/${local.update_schematic_id}/${local.update_version}/${var.talos_image.platform}-${var.talos_image.arch}.raw.gz"
  update_image_id = "${local.update_schematic_id}_${local.update_version}"
}

data "http" "schematic_id" {
  url          = "${var.talos_image.factory_url}/schematics"
  method       = "POST"
  request_body = local.schematic
}

data "http" "updated_schematic_id" {
  url          = "${var.talos_image.factory_url}/schematics"
  method       = "POST"
  request_body = local.update_schematic
}

resource "proxmox_virtual_environment_download_file" "talos_image" {
  for_each = toset(distinct([for k, v in var.cluster_config.nodes : "${v.host_node}_${v.update == true ? local.update_image_id : local.image_id}"]))

  node_name    = split("_", each.key)[0]
  content_type = "iso"
  datastore_id = var.talos_image.proxmox_datastore

  file_name               = "talos-${split("_",each.key)[1]}-${split("_", each.key)[2]}-${var.talos_image.platform}-${var.talos_image.arch}.img"
  url = "${var.talos_image.factory_url}/image/${split("_", each.key)[1]}/${split("_", each.key)[2]}/${var.talos_image.platform}-${var.talos_image.arch}.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false
}
