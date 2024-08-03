

```shell
pvesm alloc local-zfs 8000 vm-8000-app-config 1G
```

https://pve.proxmox.com/pve-docs/api-viewer/#/nodes/{node}/storage/{storage}/content

```shell
curl --request POST \
  --url https://192.168.1.62:8006/api2/json/nodes/abel/storage/local-zfs/content \
  --header 'Authorization: PVEAPIToken=root@pam!tofu=<UUID>' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data vmid=9999 \
  --data filename=vm-9999-pv-test \
  --data size=1G \
  --data format=raw
```

## rm state

```shell
tofu state rm "module.volumes.module.proxmox-volume[\"pv-lidarr-config\"].restapi_object.proxmox-volume" 
tofu state rm "module.volumes.module.proxmox-volume[\"pv-radarr-config\"].restapi_object.proxmox-volume" 
tofu state rm "module.volumes.module.proxmox-volume[\"pv-sonarr-config\"].restapi_object.proxmox-volume" 
tofu state rm "module.volumes.module.proxmox-volume[\"pv-plex-config\"].restapi_object.proxmox-volume" 
tofu state rm "module.volumes.module.proxmox-volume[\"pv-jellyfin-config\"].restapi_object.proxmox-volume" 
tofu state rm "module.volumes.module.proxmox-volume[\"pv-qbittorrent-config\"].restapi_object.proxmox-volume" 
```

## import proxmox volume

```shell
tofu import 'module.volumes.module.proxmox-volume["pv-jellyfin-config"].restapi_object.proxmox-volume' /api2/json/nodes/euclid/storage/local-zfs/content/local-zfs:vm-9999-pv-jellyfin-config
tofu import 'module.volumes.module.proxmox-volume["pv-keycloak-db"].restapi_object.proxmox-volume' /api2/json/nodes/euclid/storage/local-zfs/content/local-zfs:vm-9999-pv-keycloak-db
tofu import 'module.volumes.module.proxmox-volume["pv-lidarr-config"].restapi_object.proxmox-volume' /api2/json/nodes/cantor/storage/local-zfs/content/local-zfs:vm-9999-pv-lidarr-config
tofu import 'module.volumes.module.proxmox-volume["pv-netbird-management"].restapi_object.proxmox-volume' /api2/json/nodes/abel/storage/local-zfs/content/local-zfs:vm-9999-pv-netbird-management
tofu import 'module.volumes.module.proxmox-volume["pv-netbird-signal"].restapi_object.proxmox-volume' /api2/json/nodes/abel/storage/local-zfs/content/local-zfs:vm-9999-pv-netbird-signal
tofu import 'module.volumes.module.proxmox-volume["pv-plex-config"].restapi_object.proxmox-volume' /api2/json/nodes/abel/storage/local-zfs/content/local-zfs:vm-9999-pv-plex-config
tofu import 'module.volumes.module.proxmox-volume["pv-prometheus"].restapi_object.proxmox-volume' /api2/json/nodes/abel/storage/local-zfs/content/local-zfs:vm-9999-pv-prometheus
tofu import 'module.volumes.module.proxmox-volume["pv-prowlarr-config"].restapi_object.proxmox-volume' /api2/json/nodes/euclid/storage/local-zfs/content/local-zfs:vm-9999-pv-prowlarr-config
tofu import 'module.volumes.module.proxmox-volume["pv-radarr-config"].restapi_object.proxmox-volume' /api2/json/nodes/cantor/storage/local-zfs/content/local-zfs:vm-9999-pv-radarr-config
tofu import 'module.volumes.module.proxmox-volume["pv-remark42"].restapi_object.proxmox-volume' /api2/json/nodes/euclid/storage/local-zfs/content/local-zfs:vm-9999-pv-remark42
tofu import 'module.volumes.module.proxmox-volume["pv-sonarr-config"].restapi_object.proxmox-volume' /api2/json/nodes/cantor/storage/local-zfs/content/local-zfs:vm-9999-pv-sonarr-config
tofu import 'module.volumes.module.proxmox-volume["pv-torrent-config"].restapi_object.proxmox-volume' /api2/json/nodes/euclid/storage/local-zfs/content/local-zfs:vm-9999-pv-torrent-config
```

## import persistent volume

```shell
tofu state rm module.volumes.module.persistent-volume
```

```shell
tofu import 'module.volumes.module.persistent-volume["pv-jellyfin-config"].kubernetes_persistent_volume.pv' pv-jellyfin-config
tofu import 'module.volumes.module.persistent-volume["pv-keycloak-db"].kubernetes_persistent_volume.pv' pv-keycloak-db
tofu import 'module.volumes.module.persistent-volume["pv-lidarr-config"].kubernetes_persistent_volume.pv' pv-lidarr-config
tofu import 'module.volumes.module.persistent-volume["pv-netbird-management"].kubernetes_persistent_volume.pv' pv-netbird-management
tofu import 'module.volumes.module.persistent-volume["pv-netbird-signal"].kubernetes_persistent_volume.pv' pv-netbird-signal
tofu import 'module.volumes.module.persistent-volume["pv-plex-config"].kubernetes_persistent_volume.pv' pv-plex-config
tofu import 'module.volumes.module.persistent-volume["pv-prometheus"].kubernetes_persistent_volume.pv' pv-prometheus
tofu import 'module.volumes.module.persistent-volume["pv-prowlarr-config"].kubernetes_persistent_volume.pv' pv-prowlarr-config
tofu import 'module.volumes.module.persistent-volume["pv-radarr-config"].kubernetes_persistent_volume.pv' pv-radarr-config
tofu import 'module.volumes.module.persistent-volume["pv-remark42"].kubernetes_persistent_volume.pv' pv-remark42
tofu import 'module.volumes.module.persistent-volume["pv-sonarr-config"].kubernetes_persistent_volume.pv' pv-sonarr-config
tofu import 'module.volumes.module.persistent-volume["pv-torrent-config"].kubernetes_persistent_volume.pv' pv-torrent-config
```