# Setup cluster with kubeadm

## Proxmox (optional)

## Debian 12 – Bookworm

Enable `sudo` for the user

```shell
~$ su -
~# usermod -aG sudo <user>
~# apt install sudo
~# exit
~$ exit
`

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

## Install prerequisites

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

Install vert tools

```shell
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gpg
```

Add key and repo

```shell
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

Install kubelet, kubeadm and kubectl

```shell
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

Kubelet ≥ 1.26 requires containerd ≥ 1.6.0.

```shell
sudo apt install -y runc containerd
```

## Config

### Disable swap

Disable swap for kubelet to work properly

```shell
sudo swapoff -a
```

Comment out swap in `/etc/fstab` to disable swap on boot

```shell
sudo sed -e '/swap/ s/^#*/#/' -i /etc/fstab
```

### Forwarding IPv4 and letting iptables see bridged traffic

https://kubernetes.io/docs/setup/production-environment/container-runtimes/#install-and-configure-prerequisites

```shell
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
```

```shell
sudo modprobe overlay
sudo modprobe br_netfilter
```

Persist `sysctl` params across reboot

```shell
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
```

Apply `sysctl` params without reboot

```shell
sudo sysctl --system
```

### containerd cgroups

Generate default config

```shell
containerd config default | sudo tee /etc/containerd/config.toml
```

https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd-systemd

Configure the `systemd` cgroup driver for containerd

```shell
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
```

Restart containerd

```shell
sudo systemctl restart containerd
```

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
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

For remote kubectl copy the config file to local machine

```shell
scp veh@192.168.1.50:/home/veh/.kube/config ~/.kube/config
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

## Install Cilium as CNI (Container Network Interface)

To bootstrap the cluster we can install Cilium using its namesake CLI.

For Linux this can be done by running

```shell
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
```

See the [Cilium official docs](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/) for more options.

Next we install Cilium in Kube proxy replacement mode and enable L2 announcements to reply to ARP requests.
To not run into rate limiting while doing L2 announcements we also increase the k8s rate limits.

```shell
cilium install \
  --set kubeProxyReplacement=true \
  --set l2announcements.enabled=true \
  --set externalIPs.enabled=true \
  --set k8sClientRateLimit.qps=50 \
  --set k8sClientRateLimit.burst=100
```

See [this blog post](https://blog.stonegarden.dev/articles/2023/12/migrating-from-metallb-to-cilium/#l2-announcements)
for more details.

Validate install

```shell
cilium status
```

## Cilium LB IPAM

For [Cilium to act as a load balancer](https://docs.cilium.io/en/stable/network/lb-ipam/) and start assigning IPs
to `LoadBalancer` `Service` resources we need to create a `CiliumLoadBalancerIPPool` with a valid pool.

Edit the cidr range to fit your network before applying it

```shell
kubectl apply -f infra/cilium/ip-pool.yaml
```

Next create a `CiliumL2AnnouncementPolicy` to announce the assigned IPs.
Leaving the `interfaces` field empty announces on all interfaces.

```shell
kubectl apply -f infra/cilium/announce.yaml
```

# Sealed Secrets

Used to create encrypted secrets

```shell
kubectl apply -k infra/sealed-secrets
```

Be sure to store the generated sealed secret key in a safe place!

```shell
kubectl -n kube-system get secrets
```

*NB!*: There will be errors if you use my sealed secrets as you (hopefully) don't have the decryption key

# Gateway API

```shell
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/experimental-install.yaml
```

# Cert-manager

```shell
kubectl kustomize --enable-helm infra/cert-manager | kubectl apply -f -
```

# Traefik

Change the `io.cilium/lb-ipam-ips` annotation in `infra/traefik/values.yaml` to a valid IP address for your network.

Install Traefik

```shell
kubectl kustomize --enable-helm infra/traefik | kubectl apply -f -
```

## Port forward Traefik

Port forward Traefik ports in router from 8000 to 80 for http and 4443 to 443 for https.
IP can be found with `kubectl get svc` (it should be the same as the one you gave in the annotation).

# Test-application (Optional)

Deploy a test-application by editing the manifests in `apps/test/whoami` and apply them

```shell
kubectl apply -k apps/test/whoami
```

An unsecured test-application `whoami` should be available at [https://test.${DOMAIN}](https://test.${DOMAIN}).
If you configured `apps/test/whoami/traefik-forward-auth` correctly a secured version should be available
at [https://whoami.${DOMAIN}](https://whoami.${DOMAIN}).

# Argo CD

[ArgoCD](https://argo-cd.readthedocs.io/en/stable/getting_started/) is used to bootstrap the rest of the cluster.
The cluster uses a combination of Helm and Kustomize to configure infrastructure and applications.
For more details read [this blog post](https://blog.stonegarden.dev/articles/2023/09/argocd-kustomize-with-helm/)

```shell
kubectl kustomize --enable-helm infra/argocd | kubectl apply -f -
```

Get ArgoCD initial secret by running

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

Create a token

```shell
kubectl -n kubernetes-dashboard create token admin-user
```

# ApplicationSets

*NB!*: This will not work before you've changed all the domain names and IP addresses.

Once you've tested everything get the ball rolling with

```shell
kubectl apply -k sets
```

# Cleanup

```shell
kubectl drain gauss --delete-emptydir-data --force --ignore-daemonsets
sudo kubeadm reset
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
```
