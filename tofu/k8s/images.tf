resource "proxmox_virtual_environment_download_file" "debian_12_bookworm" {
  provider     = proxmox.euclid
  node_name    = var.euclid.node_name
  content_type = "iso"
  datastore_id = "local"

  file_name          = "debian-12-generic-amd64-20240201-1644.img"
  url                = "https://cloud.debian.org/images/cloud/bookworm/20240211-1654/debian-12-generic-amd64-20240211-1654.qcow2"
  checksum           = "b679398972ba45a60574d9202c4f97ea647dd3577e857407138b73b71a3c3c039804e40aac2f877f3969676b6c8a1ebdb4f2d67a4efa6301c21e349e37d43ef5"
  checksum_algorithm = "sha512"
}

resource "proxmox_virtual_environment_download_file" "debian_12_bpo" {
  provider     = proxmox.abel
  node_name    = var.abel.node_name
  content_type = "iso"
  datastore_id = "local"

  file_name          = "debian-12-backports-generic-amd64-20240429-1732.img"
  url                = "https://cloud.debian.org/images/cloud/bookworm-backports/20240429-1732/debian-12-backports-generic-amd64-20240429-1732.qcow2"
  checksum           = "3e28e90c97b135518fef8f3c0a5950e557d236a72eeda6e1abea91c79a1e9dc0a2c46c73dd2541a6b758afed4aa6de329d89d7906da5e02c6208d9e91e779987"
  checksum_algorithm = "sha512"
}