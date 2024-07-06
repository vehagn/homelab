module "proxmox-volume" {
  for_each = var.volumes
  source  = "./proxmox-volume"

  providers = {
    restapi = restapi
  }

  proxmox_api = var.proxmox_api
  volume = {
    name = each.key
    node = each.value.node
    size = each.value.size
  }
}

module "persistent-volume" {
  for_each = var.volumes
  source = "./persistent-volume"

  providers = {
    kubernetes = kubernetes
  }

  volume = {
    name          = each.key
    capacity      = each.value.size
    volume_handle = "${var.proxmox_api.cluster_name}/${module.proxmox-volume[each.key].node}/${module.proxmox-volume[each.key].storage}/${module.proxmox-volume[each.key].filename}"
  }
}
