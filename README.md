<div align="center">

<img src="https://raw.githubusercontent.com/vehagn/homelab/main/docs/assets/kubernetes.svg" width="144px" alt="Kubernetes logo"/>

# 🪨 Kubernetes Homelab 🏡

</div>

---

## 📝 Overview

This is the [IaC](https://en.wikipedia.org/wiki/Infrastructure_as_code) configuration for my homelab.
It's mainly powered by [Kubernetes](https://kubernetes.io/) and I do my best to adhere to GitOps practices.

To organise all the configuration I've opted for an approach using Kustomized Helm with Argo CD which I've explained in
more detail [here](https://blog.stonegarden.dev/articles/2023/09/argocd-kustomize-with-helm/).

I try to journal my adventures and exploits on my [blog](https://blog.stonegarden.dev) which is hosted by this repo.

## 🧑‍💻 Getting Started

If you're new to Kubernetes I've written a fairly thorough guide
on [Bootstrapping k3s with Cilium](https://blog.stonegarden.dev/articles/2024/02/bootstrapping-k3s-with-cilium/).
In the article I try to guide you from a fresh Debian 12 Bookworm install to a working cluster using
the [k3s](https://k3s.io) flavour of Kubernetes with [Cilium](https://cilium.io) as a [CNI](https://www.cni.dev)
and [IngressController](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/).

I've also written an article on how to get started
with [Kubernetes on Proxmox](https://blog.stonegarden.dev/articles/2024/03/proxmox-k8s-with-cilium/) if virtualisation
is more your thing.

A third option is the [Quickstart](docs/QUICKSTART.md) in the docs-folder.

I also have a ["mini-cluster" repo](https://gitlab.com/vehagn/mini-homelab) which might be easier to start understanding
over at GitLab.

## ⚙️ Core Components

* [Argo CD](https://argo-cd.readthedocs.io/en/stable/): Declarative, GitOps continuous delivery tool for Kubernetes.
* [Cert-manager](https://cert-manager.io/): Cloud native certificate management.
* [Cilium](https://cilium.io/): eBPF-based Networking, Observability, Security.
* [OpenTofu](https://opentofu.org/): The open source infrastructure as code tool.
* [Sealed-secrets](https://github.com/bitnami-labs/sealed-secrets): Encrypt your Secret into a SealedSecret, which is
  safe to store - even inside a public repository.

## 📂 Folder Structure

* `apps`: Different applications that I run in the cluster.
* `charts`: Tailor made Helm charts for this cluster.
* `docs`: Supplementary documentation.
* `infra`: Configuration for core infrastructure components
* `machines`: OpenTofu/Terraform configuration. Each sub folder is a physical machine.
* `sets`: Holds Argo CD Applications that points to the `apps` and `infra` folders for automatic Git-syncing.

## 🖥️ Hardware

| Name   | Device                    | CPU             | RAM            | Storage    | Purpose |
|--------|---------------------------|-----------------|----------------|------------|---------|
| Gauss  | Dell Precision Tower 5810 | Xeon E5-1650 v3 | 64 GB DDR4 ECC | 14 TiB HDD | -       |
| Euclid | ASUS ExpertCenter PN42    | Intel N100      | 32 GB DDR4     | -          | -       |

## 🏗️ Work in Progress

- [ ] Clean up DNS config
- [ ] Renovate for automatic updates
- [x] Build a NAS for storage
- [ ] Template Gauss
- [ ] Replace Pi Hole with AdGuard Home
- [x] Use iGPU on Euclid for video transcoding
- [x] Replace Traefik with Cilium Ingress Controller
- [ ] Cilium mTLS & SPIFFE/SPIRE

## 👷‍ Future Projects

- [x] Use Talos instead of Debian for Kubernetes
- [ ] Keycloak for auth
- [ ] Dynamic Resource Allocation for GPU
- [ ] Local LLM
- [ ] pfSense
- [ ] Use NetBird or Tailscale
- [ ] Use BGP instead of ARP
