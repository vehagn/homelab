locals {
  version      = var.image.version
  schematic    = file("${path.root}/${var.image.schematic_path}")
  schematic_id = jsondecode(data.http.schematic_id.response_body)["id"]

  update_version        = coalesce(var.image.update_version, var.image.version)
  update_schematic_path = coalesce(var.image.update_schematic_path, var.image.schematic_path)
  update_schematic      = file("${path.root}/${local.update_schematic_path}")
  update_schematic_id   = jsondecode(data.http.updated_schematic_id.response_body)["id"]

  image_id        = "${local.schematic_id}_${local.version}"
  update_image_id = "${local.update_schematic_id}_${local.update_version}"

  # Comment the above 2 lines and un-comment the below 2 lines to use the provider schematic ID instead of the HTTP one
  # ref - https://github.com/vehagn/homelab/issues/106
  # image_id = "${talos_image_factory_schematic.this.id}_${local.version}"
  # update_image_id = "${talos_image_factory_schematic.updated.id}_${local.update_version}"
}

data "http" "schematic_id" {
  url          = "${var.image.factory_url}/schematics"
  method       = "POST"
  request_body = local.schematic
}

data "http" "updated_schematic_id" {
  url          = "${var.image.factory_url}/schematics"
  method       = "POST"
  request_body = local.update_schematic
}

resource "talos_image_factory_schematic" "this" {
  schematic = local.schematic
}

resource "talos_image_factory_schematic" "updated" {
  schematic = local.update_schematic
}

# Note the ellipsis (...) after the for-loop. This collects values with same keys into a list.
# The key is purposefully made up of the values (image_id contains both schematic id and version),
# since all values under a key therefore are the same, we can simply select the first element of the value list.
# Improvements are welcome!
resource "proxmox_virtual_environment_download_file" "this" {
  for_each = {
    for k, v in var.nodes :
    "${v.host_node}_${v.update == true ? local.update_image_id : local.image_id}" => {
      host_node = v.host_node
      schematic = v.update == true ? talos_image_factory_schematic.updated.id : talos_image_factory_schematic.this.id
      version   = v.update == true ? local.update_version : local.version
    }...
  }

  node_name    = each.value[0].host_node
  content_type = "iso"
  datastore_id = var.image.proxmox_datastore

  file_name               = "talos-${each.value[0].schematic}-${each.value[0].version}-${var.image.platform}-${var.image.arch}.img"
  url                     = "${var.image.factory_url}/image/${each.value[0].schematic}/${each.value[0].version}/${var.image.platform}-${var.image.arch}.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false
}
