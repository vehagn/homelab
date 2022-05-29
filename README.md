A Terraform script to provision a Kubernetes Cluster with stuff

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

```shell
sudo kubeadm init
```

## Set up kubectl
https://kubernetes.io/docs/tasks/tools/

```shell
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Install CNI
We choose Cilium
https://docs.cilium.io/en/stable/gettingstarted/k8s-install-helm/

```shell
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.11.5 --namespace kube-system
```

## (Optional) Remove taint for single node use
```shell
kubectl taint nodes --all node-role.kubernetes.io/control-plane- node-role.kubernetes.io/master-
```

## Deploy using Terraform
https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/guides/getting-started
```shell
terraform plan 
terraform apply
```

## Cleanup
```shell
kubectl drain <node name> --delete-emptydir-data --force --ignore-daemonsets
kubeadm reset
```