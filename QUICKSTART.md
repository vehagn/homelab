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
kubectl apply -f metallb/00-manifest.yml
```

## Configure MetalLB

```shell
kubectl apply -f metallb/02-configration.yml
```

# Traefik

https://doc.traefik.io/traefik/v2.8/user-guides/crd-acme/

## Create Traefik CRDs

```shell
kubectl apply -f traefik/00-crd-definition.yml
kubectl apply -f traefik/01-crd-rbac.yml
```

## Create Service

```shell
kubectl apply -f traefik/02-service.yml
```

## Create Deployment

```shell
kubectl apply -f traefik/03-deployment.yml
```

## Create test application "whoami" with IngressRoutes

```shell
kubectl apply -f whoami/00-whoami.yml
```