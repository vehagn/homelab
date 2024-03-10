# Proxmox config
https://github.com/tteck/Proxmox

```shell
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/post-pve-install.sh)"
```

```shell
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/microcode.sh)"
```

https://pve.proxmox.com/wiki/PCI_Passthrough#Verifying_IOMMU_parameters
https://pve.proxmox.com/pve-docs/pve-admin-guide.html#sysboot_edit_kernel_cmdline
https://www.reddit.com/r/homelab/comments/18jx15t/trouble_with_enabling_iommu_pcie_passthrough_81/kdnlyhd/


```shell
root@gauss:~# update-grub
Generating grub configuration file ...
W: This system is booted via proxmox-boot-tool:
W: Executing 'update-grub' directly does not update the correct configs!
W: Running: 'proxmox-boot-tool refresh'
```

This means edit /etc/kernel/cmdline

add
```shell
intel_iommu=on
```

```shell
dmesg | grep -e DMAR -e IOMMU
...
DMAR: IOMMU enabled
```



Nvidia
```shell
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf 
echo "blacklist nvidia*" >> /etc/modprobe.d/blacklist.conf 
```
Intel
```shell
echo "blacklist i915" >> /etc/modprobe.d/blacklist.conf
```

```shell
pvesh get /nodes/<NODE_NAME>/hardware/pci --pci-class-blacklist ""
```

https://3os.org/infrastructure/proxmox/gpu-passthrough/igpu-passthrough-to-vm/#linux-virtual-machine-igpu-passthrough-configuration

```shell
 sudo lspci -nnv | grep VGA
```

## Pass through Disk
https://pve.proxmox.com/wiki/Passthrough_Physical_Disk_to_Virtual_Machine_(VM)

```shell
apt install lshw
```

```shell
lsblk |awk 'NR==1{print $0" DEVICE-ID(S)"}NR>1{dev=$1;printf $0" ";system("find /dev/disk/by-id -lname \"*"dev"\" -printf \" %p\"");print "";}'|grep -v -E 'part|lvm'
```

```shell
veh@gauss:~$ lsblk |awk 'NR==1{print $0" DEVICE-ID(S)"}NR>1{dev=$1;printf $0" ";system("find /dev/disk/by-id -lname \"*"dev"\" -printf \" %p\"");print "";}'|grep -v -E 'part|lvm'
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT DEVICE-ID(S)
sda           8:0    0 476.9G  0 disk   /dev/disk/by-id/ata-ADATA_SSD_SX900_512GB-DL2_7E5020000320 /dev/disk/by-id/wwn-0x5707c1800009389f
sh: 1: Syntax error: EOF in backquote substitution
sdb           8:16   0  12.7T  0 disk /var/lib/kubelet/pods/19ca1c6d-014b-4941-9df9-31ad06e6d0c3/volumes/kubernetes.io~local-volume/plex-media-pv  /dev/disk/by-id/ata-WDC_WD140EFGX-68B0GN0_Y6G2TE5C /dev/disk/by-id/wwn-0x5000cca2adc1446e
sdc           8:32   0   1.8T  0 disk   /dev/disk/by-id/ata-WDC_WD20EFRX-68EUZN0_WD-WCC4M1DPTXE7 /dev/disk/by-id/wwn-0x50014ee2bafd4fac
sh: 1: Syntax error: EOF in backquote substitution
sr0          11:0    1  1024M  0 rom    /dev/disk/by-id/ata-PLDS_DVD+_-RW_DS-8ABSH_9F42J736394B653H4A02
nvme0n1     259:0    0 931.5G  0 disk   /dev/disk/by-id/nvme-WD_BLACK_SN770_1TB_23413H401146 /dev/disk/by-id/nvme-eui.e8238fa6bf530001001b444a414eafc0
sh: 1: Syntax error: EOF in backquote substitution
```

```shell
qm set 100 -scsi2 /dev/disk/by-id/ata-WDC_WD20EFRX-68EUZN0_WD-WCC4M1DPTXE7
...
update VM 100: -scsi2 /dev/disk/by-id/ata-WDC_WD20EFRX-68EUZN0_WD-WCC4M1DPTXE7
```

```shell
qm set 100 -scsi3 /dev/disk/by-id/ata-WDC_WD140EFGX-68B0GN0_Y6G2TE5C
```

```shell
sdc           8:32   0   1.8T  0 disk 
|-sdc1        8:33   0   512G  0 part /disk/etc
`-sdc2        8:34   0   1.3T  0 part /disk/var
```


```shell
veh@gauss:~$ cat /etc/fstab 
# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a
# device; this may be used with UUID= as a more robust way to name devices
# that works even if disks are added and removed. See fstab(5).
#
# systemd generates mount units based on this file, see systemd.mount(5).
# Please run 'systemctl daemon-reload' after making changes here.
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
# / was on /dev/sda1 during installation
UUID=6116ff41-36cf-43cc-81c2-3b76a6586c68 /               ext4    errors=remount-ro 0       1
# /home was on /dev/sda7 during installation
UUID=c9355084-506e-4bfc-81eb-b20833175f0c /home           ext4    defaults        0       2
# /tmp was on /dev/sda6 during installation
UUID=025b6fcd-713d-4954-81dc-99c0fa7785c9 /tmp            ext4    defaults        0       2
# /var was on /dev/sda5 during installation
UUID=632f8ab8-794d-4d5b-870a-2138c64fb22a /var            ext4    defaults        0       2
/dev/sr0        /media/cdrom0   udf,iso9660 user,noauto     0       0
UUID=2ee1ed03-6306-442a-80b6-c581dfc135d0 /disk/data      ext4    defaults        0       2
UUID=e909c1e9-d7ab-4bfa-9ffc-fd24189d7ac6 /disk/etc       ext4    defaults        0       2
UUID=8b7d130b-87f8-40f9-b25a-48a5c1e41dbd /disk/var       ext4    defaults        0       2
```

```shell
veh@gauss:~$ sudo blkid
/dev/nvme0n1p2: UUID="5B5B-D058" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="705665bc-7474-4797-80cf-352fb4fd26cd"
/dev/nvme0n1p3: LABEL="rpool" UUID="3507575724543500591" UUID_SUB="13907707580269482486" BLOCK_SIZE="4096" TYPE="zfs_member" PARTUUID="832bb88c-ef55-47b9-a539-dffb8a39f046"
/dev/sdb: UUID="2ee1ed03-6306-442a-80b6-c581dfc135d0" BLOCK_SIZE="4096" TYPE="ext4"
/dev/sda1: UUID="6116ff41-36cf-43cc-81c2-3b76a6586c68" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="7358989f-01"
/dev/sda5: UUID="632f8ab8-794d-4d5b-870a-2138c64fb22a" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="7358989f-05"
/dev/sda6: UUID="025b6fcd-713d-4954-81dc-99c0fa7785c9" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="7358989f-06"
/dev/sda7: UUID="c9355084-506e-4bfc-81eb-b20833175f0c" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="7358989f-07"
/dev/sdc1: UUID="e909c1e9-d7ab-4bfa-9ffc-fd24189d7ac6" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="9261854f-1c03-ce47-b9df-417d7c48b7d9"
/dev/sdc2: UUID="8b7d130b-87f8-40f9-b25a-48a5c1e41dbd" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="8ef5bcde-692a-1e42-bcec-62338fd25f58"
/dev/nvme0n1p1: PARTUUID="4c3a80fe-2a31-4d90-b700-25879c905187"
```

```shell
 qm create 106 \
    --name deb-106 \
    --agent 1 \
    --memory 4096 \
    --bios ovmf \
    --sockets 1 --cores 4 \
    --cpu host \
    --net0 virtio,bridge=vmbr0 \
    --scsihw virtio-scsi-single \
    --boot order='scsi0' \
    --efidisk0 local-lvm:0 \
    --ide0 local-lvm:cloudinit \
    --machine q35 
```

## OpenTofu/Terraform

https://opentofu.org/

https://registry.terraform.io/providers/bpg/proxmox/latest/docs


## PN42 - k8s

```shell
sudo kubeadm init --skip-phases=addon/kube-proxy
```

