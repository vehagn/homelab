# Setup cluster with kubeadm

Disable swap for kubelet to work properly

```shell
swapoff -a
```

## Install prerequisites

```shell
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y containerd conntrack socat kubelet kubeadm kubectl 
```

cri-ctl: https://github.com/kubernetes-sigs/cri-tools
TODO: nerdctl?

We are going to use Cilium kube-proxy (TODO)

## Initialise cluster

```shell
sudo kubeadm init 
```

## Set up kubectl

https://kubernetes.io/docs/tasks/tools/

```shell
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

For remote kubectl copy the config file to local machine

```shell
scp veh@192.168.1.12:/home/veh/.kube/config ~/.kube/config
```

## (Optional) Remove taint for single node use

Get taints on nodes

```shell
kubectl get nodes -o json | jq '.items[].spec.taints'
```

Remove taint on master node to allow scheduling of all deployments

```shell
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

## Install Cilium as Container Network Interface (CNI)

https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/

Install Cilium CLI

```shell
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
```

Install Cilium

```shell
cilium install
```

// TODO: Directly by Helm chart
```shell
helm template --namespace kube-system cilium cilium/cilium --version 1.12.1 --set cluster.id=0,cluster.name=kubernetes,encryption.nodeEncryption=false,kubeProxyReplacement=disabled,operator.replicas=1,serviceAccounts.cilium.name=cilium,serviceAccounts.operator.name=cilium-operator,tunnel=vxlan
```

Validate install

```shell
cilium status
```

### (Optional) Replace kube-proxy with Cilium [TODO]

https://docs.cilium.io/en/v1.12/gettingstarted/kubeproxy-free/

*NB* Cluster should be initialised with

```shell
sudo kubeadm init --skip-phases=addon/kube-proxy
```

## MetalLB

For load balancing

https://metallb.universe.tf/installation/

Installation
https://raw.githubusercontent.com/metallb/metallb/v0.13.5/config/manifests/metallb-native.yaml

```shell
kubectl apply -f infra/metallb/00-manifest.yml
```

Configure IP-pool and advertise as Level 2
https://metallb.universe.tf/configuration/

```yaml
kubectl apply -f infra/metallb/01-configuration.yml
```

# Traefik

## Install using Terraform and Helm

```shell
terraform init
terraform plan
terraform apply
```

**NB:** It appears we need the "volume-permissions" init container for Traefik if using `StorageClass` with
provisioner `kubernetes.io/no-provisioner`

## Port forward Traefik

Port forward Traefik ports in router from 8000 to 80 for http and 4443 to 443 for https.
IP can be found with `kubectl get svc`.

# Test-application

A test-application `whoami` should be available at `https://whoami.${DOMAIN}`.

# Cleanup

```shell
kubectl drain gauss --delete-emptydir-data --force --ignore-daemonsets
sudo kubeadm reset
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
sudo ipvsadm -C
```