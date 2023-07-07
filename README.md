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

Kubelet 1.26 requires containerd 1.6.0 or later.

## Initialise cluster

We are going to use cilium in place of kube-proxy
https://docs.cilium.io/en/v1.12/gettingstarted/kubeproxy-free/

```shell
sudo kubeadm init --skip-phases=addon/kube-proxy
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

Validate install

```shell
cilium status
```

## MetalLB

For load balancing

https://metallb.universe.tf/installation/

```shell
kubectl apply -k infra/metallb
```

# Traefik

Install Traefik

```shell
kubectl kustomize --enable-helm infra/traefik | kubectl apply -f -
```

## Port forward Traefik

Port forward Traefik ports in router from 8000 to 80 for http and 4443 to 443 for https.
IP can be found with `kubectl get svc`.

# Test-application

## Generate secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: traefik-forward-auth-secrets
  namespace: whoami
type: Opaque
data:
  google-client-id: <...>
  google-client-secret: <...>
  secret: <...>
```

Deploy a test-application by running

```shell
kubectl apply -k apps/whoami
```

An unsecured test-application `whoami` should be available at [https://test.${DOMAIN}](https://test.${DOMAIN}).
If you configured `apps/whoami/traefik-forward-auth` correctly a secured version should be available
at [https://whoami.${DOMAIN}](https://whoami.${DOMAIN})

# ArgoCD

[ArgoCD](https://argo-cd.readthedocs.io/en/stable/getting_started/) is configured to bootstrap the rest of the cluster

```shell
kubectl apply -k infra/argocd
```

Get ArgoCD initial secret
```shell
kubectl -n argocd get secrets argocd-initial-admin-secret -o json | jq -r .data.password | base64 -d
```

# Kubernetes Dashboard

An OIDC (traefik-forward-auth)
protected [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/) can be
deployed using

```shell
kubectl apply -k infra/dashboard
```

# ApplicationSets

Once you've tested everything get the ball rolling with

```shell
kubectl apply -k sets
```

# Cleanup

```shell
kubectl drain gauss --delete-emptydir-data --force --ignore-daemonsets
sudo kubeadm reset
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
sudo ipvsadm -C
```

# Troubleshooting

Kubernetes 1.26 requires containerd 1.6.0 or later due to the removal of support for CRI
version `v1alpha2` ([link](https://kubernetes.io/blog/2022/11/18/upcoming-changes-in-kubernetes-1-26/#cri-api-removal)).

Make sure that `runc` is properly configured in containerd.

NB: Make sure the correct `containerd` daemon is running. 
(Check the loaded `containerd` service definition as reported by `systemctl status containerd`)
Follow https://github.com/containerd/containerd/blob/main/docs/getting-started.md for further instructions.

```shell
sudo cat /etc/containerd/config.toml
```

```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
runtime_path = "/usr/bin/runc"
runtime_type = "io.containerd.runc.v2"
```

## Wrong containerd version

1.7.x doesn't work?

## Sealed Secrets

Restart pod after applying master-key