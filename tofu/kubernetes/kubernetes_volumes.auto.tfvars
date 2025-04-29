kubernetes_volumes = {
  pv-sonarr = {
    node = "cantor"
    size = "4G"
  }
  pv-radarr = {
    node = "cantor"
    size = "4G"
  }
  pv-lidarr = {
    node = "cantor"
    size = "4G"
  }
  pv-prowlarr = {
    node = "euclid"
    size = "1G"
  }
  pv-torrent = {
    node = "euclid"
    size = "1G"
  }
  pv-audiobookshelf = {
    node = "euclid"
    size = "4G"
  }
  pv-remark42 = {
    node = "euclid"
    size = "1G"
  }
  pv-authelia-postgres = {
    node = "euclid"
    size = "2G"
  }
  pv-lldap-postgres = {
    node = "euclid"
    size = "2G"
  }
  pv-jellyfin-config = {
    node = "euclid"
    size = "12G"
  }
  pv-netbird-signal = {
    node = "abel"
    size = "512M"
  }
  pv-netbird-management = {
    node = "abel"
    size = "512M"
  }
  pv-plex = {
    node = "abel"
    size = "12G"
  }
  pv-prometheus = {
    node = "abel"
    size = "10G"
  }
}
