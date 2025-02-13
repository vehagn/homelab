locals {
  version   = var.image.version
  schematic = var.image.schematic

  update_version   = coalesce(var.image.update_version, var.image.version)
  update_schematic = coalesce(var.image.update_schematic, var.image.schematic)

  image_hashed        = "${local.version}_${sha256(local.schematic)}"
  update_image_hashed = "${local.update_version}_${sha256(local.update_schematic)}"

  image_filename        = "talos-${local.version}-${talos_image_factory_schematic.this.id}-${var.image.platform}-${var.image.arch}.img"
  update_image_filename = "talos-${local.update_version}-${talos_image_factory_schematic.updated.id}-${var.image.platform}-${var.image.arch}.img"

  image_url        = "${var.image.factory_url}/image/${talos_image_factory_schematic.this.id}/${local.version}/${var.image.platform}-${var.image.arch}.raw.gz"
  update_image_url = "${var.image.factory_url}/image/${talos_image_factory_schematic.updated.id}/${local.update_version}/${var.image.platform}-${var.image.arch}.raw.gz"
}

resource "talos_image_factory_schematic" "this" {
  schematic = local.schematic
}

resource "talos_image_factory_schematic" "updated" {
  schematic = local.update_schematic
}

resource "proxmox_virtual_environment_download_file" "this" {
  for_each = {
    for k, v in var.nodes :
    "${v.host_node}_${v.update == true ? local.update_image_hashed : local.image_hashed}" => {
      host_node      = v.host_node
      image_url      = "${v.update == true ? local.update_image_url : local.image_url}"
      image_filename = "${v.update == true ? local.update_image_filename : local.image_filename}"
    }
  }

  node_name    = each.value.host_node
  content_type = "iso"
  datastore_id = var.image.proxmox_datastore

  file_name               = each.value.image_filename
  url                     = each.value.image_url
  decompression_algorithm = "gz"
  overwrite               = false
}
