locals {
  version   = var.image.version
  schematic = var.image.schematic
  image_id  = "${talos_image_factory_schematic.this.id}_${local.version}"

  update_version   = coalesce(var.image.update_version, var.image.version)
  update_schematic = coalesce(var.image.update_schematic, var.image.schematic)
  update_image_id  = "${talos_image_factory_schematic.updated.id}_${local.update_version}"
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
    "${v.host_node}_${v.update == true ? local.update_image_id : local.image_id}" => {
      host_node = v.host_node
      version   = "${v.update == true ? local.update_version : local.version}"
      schematic = "${v.update == true ? talos_image_factory_schematic.updated.id : talos_image_factory_schematic.this.id}"
    }
  }

  node_name    = each.value.host_node
  content_type = "iso"
  datastore_id = var.image.proxmox_datastore

  file_name               = "talos-${each.value.schematic}-${each.value.version}-${var.image.platform}-${var.image.arch}.img"
  url                     = "${var.image.factory_url}/image/${each.value.schematic}/${each.value.version}/${var.image.platform}-${var.image.arch}.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false
}
