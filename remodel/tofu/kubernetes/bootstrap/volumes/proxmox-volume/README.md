

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