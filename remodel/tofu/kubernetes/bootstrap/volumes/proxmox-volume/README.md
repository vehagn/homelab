

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

## import

```shell
tofu import "module.volumes.module.proxmox-volume[\"pv-lidarr-config\"].restapi_object.proxmox-volume" /api2/json/nodes/cantor/storage/local-zfs/content/local-zfs:vm-9999-pv-lidarr-config
tofu import "module.volumes.module.proxmox-volume[\"pv-radarr-config\"].restapi_object.proxmox-volume" /api2/json/nodes/cantor/storage/local-zfs/content/local-zfs:vm-9999-pv-radarr-config
tofu import "module.volumes.module.proxmox-volume[\"pv-sonarr-config\"].restapi_object.proxmox-volume" /api2/json/nodes/cantor/storage/local-zfs/content/local-zfs:vm-9999-pv-sonarr-config

tofu import "module.volumes.module.proxmox-volume[\"pv-qbittorrent-config\"].restapi_object.proxmox-volume" /api2/json/nodes/euclid/storage/local-zfs/content/local-zfs:vm-9999-pv-qbittorrent-config
 
tofu import "module.volumes.module.proxmox-volume[\"pv-plex-config\"].restapi_object.proxmox-volume" /api2/json/nodes/abel/storage/local-zfs/content/local-zfs:vm-9999-pv-plex-config
tofu import "module.volumes.module.proxmox-volume[\"pv-jellyfin-config\"].restapi_object.proxmox-volume" /api2/json/nodes/abel/storage/local-zfs/content/local-zfs:vm-9999-pv-jellyfin-config
```