# Proxmox config


```shell
bash -c "$(wget -qLO - https://github.com/tteck/Proxmox/raw/main/misc/post-pve-install.sh)"
```

```shell

```


## Updates

https://pve.proxmox.com/wiki/Package_Repositories
```shell
vim /etc/apt/sources.list
```

Add no-subscription repositories for `pve` and `ceph-reef`
```shell
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" | tee /etc/apt/sources.list.d/pve-no-subscription.list
echo "deb http://download.proxmox.com/debian/ceph-reef bookworm no-subscription" | tee /etc/apt/sources.list.d/ceph-no-subscription.list
```

Remove subscription (`sources.list` or `pve-enterprise.list`??)
```shell
sudo sed -e '/enterprise.proxmox.com/ s/^#*/#/' -i /etc/apt/sources.list.d/sources.list
sudo sed -e '/enterprise.proxmox.com/ s/^#*/#/' -i /etc/apt/sources.list.d/ceph.list
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

## PCI Passthrough
https://pve.proxmox.com/wiki/PCI_Passthrough

## OpenTofu/Terraform

https://opentofu.org/

https://registry.terraform.io/providers/bpg/proxmox/latest/docs


## Debian 12 – Bookworm

Enable `sudo` for the user

```shell
~$ su -
~# usermod -aG sudo <user>
~# apt install sudo
~# exit
~$ exit
```

Enable `ssh` on server

```shell
sudo apt install openssh-server
```

On client

```shell
ssh-copy-id <user>@<ip>
```

Harden `ssh` server

```shell
echo "PermitRootLogin no" | sudo tee /etc/ssh/sshd_config.d/01-disable-root-login.conf
echo "PasswordAuthentication no" | sudo tee /etc/ssh/sshd_config.d/02-disable-password-auth.conf
echo "ChallengeResponseAuthentication no" | sudo tee /etc/ssh/sshd_config.d/03-disable-challenge-response-auth.conf
echo "UsePAM no" | sudo tee /etc/ssh/sshd_config.d/04-disable-pam.conf
sudo systemctl reload ssh
```

#####

## PN42 - k8s

```shell
kubeadm join 192.168.1.25:6443 --token mghcuo.m335pk1kuj7t55sd \
        --discovery-token-ca-cert-hash sha256:43e1ac8af318690a7c28c0ac8e6353af31c058a5915161251c3fbeb079229759 
```

## PN42 - k3s


####
https://github.com/larivierec/home-cluster

```shell
sudo apt install \
  nftables \
  nfs-common \
  curl \
  containerd \
  open-iscsi \
  vim \
  gnupg \
  net-tools \
  dnsutils
```

```shell
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

```shell
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="server" sh -s - --flannel-backend none \
        --disable traefik \
        --disable servicelb \
        --disable-network-policy \
        --disable-kube-proxy \
        --kube-controller-manager-arg bind-address=0.0.0.0 \
        --kube-scheduler-arg bind-address=0.0.0.0 \
        --etcd-expose-metrics \
        --cluster-init
```


### My own try

```shell
sudo apt install -y curl
```

```shell
curl -sfL https://get.k3s.io | sh -s - \
  --flannel-backend=none \
  --disable-kube-proxy \
  --disable traefik \
  --disable servicelb \
  --disable-network-policy \
  --etcd-expose-metrics \
  --cluster-init
```

```shell
mkdir -p $HOME/.kube
sudo cp -i /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

```shell
export KUBECONFIG=$HOME/.kube/config
```

```shell
kubectl config set-context --current --namespace kube-system
```

```shell
API_SERVER_IP=<IP>
API_SERVER_PORT=<PORT>
cilium install --set k8sServiceHost=${API_SERVER_IP} --set k8sServicePort=${API_SERVER_PORT} --version 1.15
```

###


```shell
/usr/local/bin/k3s-uninstall.sh
/usr/local/bin/k3s-agent-uninstall.sh
```

```shell
sudo cat /var/lib/rancher/k3s/server/token
```

```shell
curl -sfL https://get.k3s.io | K3S_TOKEN="<token-from-server>" K3S_URL=https://<ip:port> sh -
```

cilium install needs the config file in the regular location
```shell
sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
```
