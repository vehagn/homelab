locals {
  filename = "vm-${var.volume.vmid}-${var.volume.name}"
}

resource "restapi_object" "proxmox-volume" {
  path = "/api2/json/nodes/${var.volume.node}/storage/${var.volume.storage}/content"

  id_attribute = "data"

  debug = true

  data = jsonencode({
    vmid     = var.volume.vmid
    filename = local.filename
    size     = var.volume.size
    format   = var.volume.format
  })

  // Proxmox returns a different object which we ignore.
  // The size is also returned in bytes, not with prefix, e.g. 1G, 512Mi.
  // Setting to false (default) triggers a change each run
  ignore_all_server_changes = true

  // Providing a supported parameter that doesn't do anything.
  // Supplying either `null` or an empty object makes this fall back to the `data` object.
  update_data = jsonencode({
    node = var.volume.node
  })

  lifecycle {
    prevent_destroy = false
  }
}

output "node" {
  value = var.volume.node
}

output "storage" {
  value = var.volume.storage
}

output "filename" {
  value = local.filename
}
