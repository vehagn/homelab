module "proxmox-volume" {
  for_each = var.volumes
  source   = "./proxmox-volume"

  providers = {
    restapi = restapi
  }

  volume = {
    name    = each.key
    node    = each.value.node
    size    = each.value.size
    storage = each.value.storage
    vmid    = each.value.vmid
    format  = each.value.format
  }
}

module "persistent-volume" {
  for_each = var.volumes
  source   = "./persistent-volume"

  providers = {
    kubernetes = kubernetes
  }

  volume = {
    name          = each.key
    capacity      = each.value.size
    volume_handle = "${var.proxmox_api.cluster_name}/${module.proxmox-volume[each.key].node}/${module.proxmox-volume[each.key].storage}/${module.proxmox-volume[each.key].filename}"
    storage       = each.value.storage
  }
}
