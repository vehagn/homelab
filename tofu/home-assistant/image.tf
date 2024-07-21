resource "null_resource" "haos_image" {
  triggers = {
    on_version_change = var.haos_version
    filename = var.local_file
  }

  provisioner "local-exec" {
    command = "curl -s -L ${var.haos_download_url}/${var.haos_version}/haos_ova-${var.haos_version}.qcow2.xz | xz -d > ${var.local_file}"
  }

    provisioner "local-exec" {
      when    = destroy
      command = "rm ${self.triggers.filename}"
    }
}

resource "proxmox_virtual_environment_file" "haos_generic_image" {
  depends_on = [null_resource.haos_image]
  node_name    = var.proxmox_node.name
  datastore_id = var.proxmox_node.image_datastore

  content_type = "iso"

  source_file {
    path      = var.local_file
    file_name = "haos_ova-${var.haos_version}.img"
  }
}
