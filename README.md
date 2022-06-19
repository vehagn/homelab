A Terraform script to provision a Kubernetes Cluster with stuff


# MAYBE JUST USE MINIKUBE?

```
minikube start --network-plugin=cni --cni=false
```

Need CNI (Cilium) LoadBalancer (MetaLB) and IngressController (Traefik) I think.
https://pgillich.medium.com/setup-on-premise-kubernetes-with-kubeadm-metallb-traefik-and-vagrant-8a9d8d28951a

Interesting: https://github.com/Mosibi/mosibi-kubernetes

# Setup cluster with kubeadm

Disable swap for kubelet to work properly
```shell
swapoff -a
```

```shell
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y containerd conntrack socat kubelet kubeadm kubectl 
```

cri-ctl: https://github.com/kubernetes-sigs/cri-tools
nerdctl?


We are going to use Cilium kube-proxy (TODO)
```shell
sudo kubeadm init --skip-phases=addon/kube-proxy (TODO)
sudo kubeadm init 
```

## Set up kubectl
https://kubernetes.io/docs/tasks/tools/

```shell
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

For remote kubectl
```shell
scp veh@192.168.1.12:/home/veh/.kube/config ~/.kube/config
```

## (Optional) Remove taint for single node use
```shell
kubectl taint nodes --all node-role.kubernetes.io/control-plane- node-role.kubernetes.io/master-
```

## Install CNI
We choose Cilium
https://docs.cilium.io/en/stable/gettingstarted/k8s-install-helm/

```shell
cilium install
```

```shell
helm repo add cilium https://helm.cilium.io/
```

```shell
kubectl -n kube-system get pods --watch
```

### Validate
```shell
kubectl -n kube-system get pods -l k8s-app=cilium
```

## MetalLB
```shell
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb
```

## Deploy using Terraform
https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/guides/getting-started
```shell
terraform plan 
terraform apply
```

## Traefik IngressRoute CRD
https://doc.traefik.io/traefik/v2.0/routing/providers/kubernetes-crd/
```shell

```


## Cleanup
```shell
kubectl drain ratatoskr --delete-emptydir-data --force --ignore-daemonsets
sudo kubeadm reset
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
sudo ipvsadm -C
```