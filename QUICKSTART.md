# Kubernetes

## Disable swap

```shell
swapoff -a
```

## Start Kubernetes

```shell
sudo kubeadm init
```

## Set up kubectl

```shell
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Remove taint for single node use

```shell
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

# Cilium

## Install Cilium as a CNI

```shell
cilium install
```

# Load Balancer

## Install MetalLB for LoadBalancing

https://raw.githubusercontent.com/metallb/metallb/v0.13.5/config/manifests/metallb-native.yaml

```shell
kubectl apply -k infra/metallb
```

# Traefik

https://doc.traefik.io/traefik/v2.8/user-guides/crd-acme/

## Run Terraform-script

This will create a cert-storage `StorageClass` and a traefik-cert-pv `PersistentVolume` for use by Traefik before
installing Traefik in the `kube-system` namespace using the official Traefik Helm chart which binds to the
traefik-cert-pv `PersistentVolume` for persistent storage of certificates using the traefik `PersistentVolumeClaim`.

```shell
terraform init
terraform plan
terraform apply
```