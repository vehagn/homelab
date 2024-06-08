#resource "proxmox_virtual_environment_download_file" "debian_12_bookworm" {
#  provider     = proxmox.abel
#  node_name    = var.abel.node_name
#  content_type = "iso"
#  datastore_id = "local"
#
#  file_name          = "debian-12-generic-amd64-20240507-1740.img"
#  url                = "https://cloud.debian.org/images/cloud/bookworm/20240507-1740/debian-12-generic-amd64-20240507-1740.qcow2"
#  checksum           = "f7ac3fb9d45cdee99b25ce41c3a0322c0555d4f82d967b57b3167fce878bde09590515052c5193a1c6d69978c9fe1683338b4d93e070b5b3d04e99be00018f25"
#  checksum_algorithm = "sha512"
#}
#
#resource "proxmox_virtual_environment_download_file" "debian_12_bpo" {
#  provider     = proxmox.abel
#  node_name    = var.abel.node_name
#  content_type = "iso"
#  datastore_id = "local"
#
#  file_name          = "debian-12-backports-generic-amd64-20240429-1732.img"
#  url                = "https://cloud.debian.org/images/cloud/bookworm-backports/20240429-1732/debian-12-backports-generic-amd64-20240429-1732.qcow2"
#  checksum           = "3e28e90c97b135518fef8f3c0a5950e557d236a72eeda6e1abea91c79a1e9dc0a2c46c73dd2541a6b758afed4aa6de329d89d7906da5e02c6208d9e91e779987"
#  checksum_algorithm = "sha512"
#}

locals {
  talos = {
    version = "v1.7.4" # renovate: github-releases=siderolabs/talos
    checksum = "26e23f1bf44eecb0232d0aa221223b44f4e40806b7d12cf1a72626927da9a8a4"
  }
}

#resource "proxmox_virtual_environment_download_file" "talos_nocloud_image" {
#  provider     = proxmox.abel
#  node_name    = var.abel.node_name
#  content_type = "iso"
#  datastore_id = "local"
#
#
#  file_name          = "talos-${local.talos.version}-nocloud-amd64.img"
#  url                = "https://factory.talos.dev/image/dcac6b92c17d1d8947a0cee5e0e6b6904089aa878c70d66196bb1138dbd05d1a/v1.7.4/nocloud-amd64.iso"
##  checksum           = local.talos.checksum
##  checksum_algorithm = "sha256"
#}

resource "proxmox_virtual_environment_file" "talos_nocloud_image" {
  provider     = proxmox.abel
  node_name    = var.abel.node_name
  content_type = "iso"
  datastore_id = "local"

  source_file {
    path      = "images/talos-${local.talos.version}-nocloud-amd64.raw"
    file_name = "talos-${local.talos.version}-nocloud-amd64.img"
#    checksum  = local.talos.checksum
  }
}