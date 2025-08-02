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
tofu state rm 'module.volumes.module.proxmox-volume["pv-sonarr"].restapi_object.proxmox-volume'
tofu state rm 'module.volumes.module.proxmox-volume["pv-radarr"].restapi_object.proxmox-volume'
tofu state rm 'module.volumes.module.proxmox-volume["pv-lidarr"].restapi_object.proxmox-volume'
tofu state rm 'module.volumes.module.proxmox-volume["pv-prowlarr"].restapi_object.proxmox-volume'
tofu state rm 'module.volumes.module.proxmox-volume["pv-torrent"].restapi_object.proxmox-volume'
tofu state rm 'module.volumes.module.proxmox-volume["pv-remark42"].restapi_object.proxmox-volume'
tofu state rm 'module.volumes.module.proxmox-volume["pv-authelia-postgres"].restapi_object.proxmox-volume'
tofu state rm 'module.volumes.module.proxmox-volume["pv-lldap-postgres"].restapi_object.proxmox-volume'
tofu state rm 'module.volumes.module.proxmox-volume["pv-keycloak-postgres"].restapi_object.proxmox-volume'
tofu state rm 'module.volumes.module.proxmox-volume["pv-jellyfin-config"].restapi_object.proxmox-volume'
tofu state rm 'module.volumes.module.proxmox-volume["pv-netbird-signal"].restapi_object.proxmox-volume'
tofu state rm 'module.volumes.module.proxmox-volume["pv-netbird-management"].restapi_object.proxmox-volume'
tofu state rm 'module.volumes.module.proxmox-volume["pv-plex"].restapi_object.proxmox-volume'
tofu state rm 'module.volumes.module.proxmox-volume["pv-prometheus"].restapi_object.proxmox-volume'
```

## import proxmox volume

```shell
tofu import 'module.volumes.module.proxmox-volume["pv-sonarr"].restapi_object.proxmox-volume' /api2/json/nodes/cantor/storage/local-zfs/content/local-zfs:vm-9999-pv-sonarr
tofu import 'module.volumes.module.proxmox-volume["pv-radarr"].restapi_object.proxmox-volume' /api2/json/nodes/cantor/storage/local-zfs/content/local-zfs:vm-9999-pv-radarr
tofu import 'module.volumes.module.proxmox-volume["pv-lidarr"].restapi_object.proxmox-volume' /api2/json/nodes/cantor/storage/local-zfs/content/local-zfs:vm-9999-pv-lidarr
tofu import 'module.volumes.module.proxmox-volume["pv-prowlarr"].restapi_object.proxmox-volume' /api2/json/nodes/euclid/storage/local-zfs/content/local-zfs:vm-9999-pv-prowlarr
tofu import 'module.volumes.module.proxmox-volume["pv-torrent"].restapi_object.proxmox-volume' /api2/json/nodes/euclid/storage/local-zfs/content/local-zfs:vm-9999-pv-torrent
tofu import 'module.volumes.module.proxmox-volume["pv-remark42"].restapi_object.proxmox-volume' /api2/json/nodes/euclid/storage/local-zfs/content/local-zfs:vm-9999-pv-remark42
tofu import 'module.volumes.module.proxmox-volume["pv-authelia-postgres"].restapi_object.proxmox-volume' /api2/json/nodes/euclid/storage/local-zfs/content/local-zfs:vm-9999-pv-authelia-postgres
tofu import 'module.volumes.module.proxmox-volume["pv-lldap-postgres"].restapi_object.proxmox-volume' /api2/json/nodes/euclid/storage/local-zfs/content/local-zfs:vm-9999-pv-lldap-postgres
tofu import 'module.volumes.module.proxmox-volume["pv-keycloak-postgres"].restapi_object.proxmox-volume' /api2/json/nodes/euclid/storage/local-zfs/content/local-zfs:vm-9999-pv-keycloak-postgres
tofu import 'module.volumes.module.proxmox-volume["pv-jellyfin-config"].restapi_object.proxmox-volume' /api2/json/nodes/euclid/storage/local-zfs/content/local-zfs:vm-9999-pv-jellyfin-config
tofu import 'module.volumes.module.proxmox-volume["pv-netbird-signal"].restapi_object.proxmox-volume' /api2/json/nodes/abel/storage/local-zfs/content/local-zfs:vm-9999-pv-netbird-signal
tofu import 'module.volumes.module.proxmox-volume["pv-netbird-management"].restapi_object.proxmox-volume' /api2/json/nodes/abel/storage/local-zfs/content/local-zfs:vm-9999-pv-netbird-management
tofu import 'module.volumes.module.proxmox-volume["pv-plex"].restapi_object.proxmox-volume' /api2/json/nodes/abel/storage/local-zfs/content/local-zfs:vm-9999-pv-plex
tofu import 'module.volumes.module.proxmox-volume["pv-prometheus"].restapi_object.proxmox-volume' /api2/json/nodes/abel/storage/local-zfs/content/local-zfs:vm-9999-pv-prometheus
```

## import persistent volume

```shell
tofu state rm module.volumes.module.persistent-volume
```

```shell
tofu import 'module.volumes.module.persistent-volume["pv-sonarr"].kubernetes_persistent_volume.pv' pv-sonarr
tofu import 'module.volumes.module.persistent-volume["pv-radarr"].kubernetes_persistent_volume.pv' pv-radarr
tofu import 'module.volumes.module.persistent-volume["pv-lidarr"].kubernetes_persistent_volume.pv' pv-lidarr
tofu import 'module.volumes.module.persistent-volume["pv-prowlarr"].kubernetes_persistent_volume.pv' pv-prowlarr
tofu import 'module.volumes.module.persistent-volume["pv-torrent"].kubernetes_persistent_volume.pv' pv-torrent
tofu import 'module.volumes.module.persistent-volume["pv-remark42"].kubernetes_persistent_volume.pv' pv-remark42
tofu import 'module.volumes.module.persistent-volume["pv-authelia-postgres"].kubernetes_persistent_volume.pv' pv-authelia-postgres
tofu import 'module.volumes.module.persistent-volume["pv-lldap-postgres"].kubernetes_persistent_volume.pv' pv-lldap-postgres
tofu import 'module.volumes.module.persistent-volume["pv-keycloak-postgres"].kubernetes_persistent_volume.pv' pv-keycloak-postgres
tofu import 'module.volumes.module.persistent-volume["pv-jellyfin-config"].kubernetes_persistent_volume.pv' pv-jellyfin-config
tofu import 'module.volumes.module.persistent-volume["pv-netbird-signal"].kubernetes_persistent_volume.pv' pv-netbird-signal
tofu import 'module.volumes.module.persistent-volume["pv-netbird-management"].kubernetes_persistent_volume.pv' pv-netbird-management
tofu import 'module.volumes.module.persistent-volume["pv-plex"].kubernetes_persistent_volume.pv' pv-plex
tofu import 'module.volumes.module.persistent-volume["pv-prometheus"].kubernetes_persistent_volume.pv' pv-prometheus
```

## Backup volume on Proxmox node

list all volumes

```shell
zfs list
```

create snapshot

```shell
zfs snapshot rpool/data/<NAME>@backup
```

list snapshots

```shell
zfs list -t snapshot
```

```shell
zpool create rpool/data/<NAME>-backup
```

```shell
root@abel:~# zfs send rpool/data/<NAME>@backup | zfs receive -F -u rpool/data/<NAME>-backup
```

## Manually mount disk

```shell
qm set <vmid> -<disk_type> <storage>:<volume>
```
