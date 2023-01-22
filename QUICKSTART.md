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

# MetalLB

## Install MetalLB for LoadBalancing

https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml

```shell
kubectl apply -k infra/metallb
```

# Traefik reverse proxy

https://doc.traefik.io/traefik/v2.9/user-guides/crd-acme/

```shell
kubectl kustomize --enable-helm infra/traefik | ku apply -f -
```

# ArgoCD

https://argo-cd.readthedocs.io/en/stable/getting_started/

```shell
kubectl apply -k infra/traefik
```