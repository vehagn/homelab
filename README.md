<div align="center">

# 🪨 Homelab 🏡

Repository for home infrastructure and [Kubernetes](https://kubernetes.io/) cluster
using [GitOps](https://en.wikipedia.org/wiki/DevOps) practices.

Held together using [Proxmox VE](https://www.proxmox.com/en/proxmox-virtual-environment),
[OpenTofu](https://opentofu.org/), [Talos](https://talos.dev), [Kubernetes](https://kubernetes.io/),
[Argo CD](https://argoproj.github.io/cd/) and copious amounts of [YAML](https://yaml.org/) with some help
from [Renovate](https://www.mend.io/renovate/) and [DevContainers](https://containers.dev/).

</div>

DevContainer Usage [Instructions](.devcontainer/README.md).

---

## 📖 Overview

This repository hosts the IaC ([Infrastructure as Code](https://en.wikipedia.org/wiki/Infrastructure_as_code))
configuration for my homelab.

The Homelab is backed by [Proxmox VE](https://www.proxmox.com/en/proxmox-virtual-environment) hypervisor nodes with VMs
bootstrapped using [OpenTofu](https://opentofu.org/)/[Terraform](https://www.terraform.io/).

Most of the services run on [Talos](https://www.talos.dev/) flavoured [Kubernetes](https://kubernetes.io/),
though I'm also running a [TrueNAS](https://www.truenas.com/) VM for storage
and [Home Assistant](https://www.home-assistant.io/) VM for home automation.

To organise all the configuration I've opted for an approach using Kustomized Helm
with [Argo CD](https://argoproj.github.io/cd/) which I've explained in more
detail [in this article](https://blog.stonegarden.dev/articles/2023/09/argocd-kustomize-with-helm/).

I journal my homelab journey over at my self-hosted [blog](https://blog.stonegarden.dev).

## 🧑‍💻 Getting Started

If you're new to Kubernetes I've written a fairly thorough guide
on [Bootstrapping k3s with Cilium](https://blog.stonegarden.dev/articles/2024/02/bootstrapping-k3s-with-cilium/).
In the article I try to guide you from a fresh Debian 12 Bookworm install to a working cluster using
the [k3s](https://k3s.io) flavour of Kubernetes with [Cilium](https://cilium.io) as a [CNI](https://www.cni.dev)
and [IngressController](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/).

I've also written an article on how to get started
with [Kubernetes on Proxmox](https://blog.stonegarden.dev/articles/2024/03/proxmox-k8s-with-cilium/) if virtualisation
is more your thing.

The current iteration of my homelab runs on [Talos](https://talos.dev) Kubernetes and is set up according
to [this article](https://blog.stonegarden.dev/articles/2024/08/talos-proxmox-tofu/).

## ⚙️ Core Components

* [Proxmox VE](https://www.proxmox.com/en/proxmox-virtual-environment): Server management and KVM hypervisor.
* [OpenTofu](https://opentofu.org/): Open source infrastructure as code tool.
* [Cilium](https://cilium.io/): eBPF-based Networking, Observability, Security.
* [Proxmox CSI Plugin](https://github.com/sergelogvinov/proxmox-csi-plugin): CSI driver for storage
* [Argo CD](https://argo-cd.readthedocs.io/en/stable/): Declarative, GitOps continuous delivery tool for Kubernetes.
* [Cert-manager](https://cert-manager.io/): Cloud native certificate management.
* [Sealed-secrets](https://github.com/bitnami-labs/sealed-secrets): Encrypt your Secret into a SealedSecret, which is
  safe to store - even inside a public repository.
* [Authelia](https://www.authelia.com/): open-source authentication and authorization server
* [Gateway API](https://gateway-api.sigs.k8s.io/): Next generation of Kubernetes Ingress
* [AdGuardHome](https://github.com/AdguardTeam/AdGuardHome): Domain name server backed by Unbound
* [NetBird](https://netbird.io/): Completely self hosted VPN solution
* [CloudNativePG](https://cloudnative-pg.io/): PostgreSQL database operator

## 🗃️ Folder Structure

```shell
.
├── 📂 docs                # Documentation
├── 📂 k8s                 # Kubernetes manifests
│   ├── 📂 apps            # Applications
│   ├── 📂 infra           # Infrastructure components
│   └── 📂 sets            # Bootstrapping ApplicationSets
└── 📂 tofu                # Tofu configuration
    ├── 📂 home-assistant  # Home Assistant VM
    └── 📂 kubernetes      # Kubernetes VM configuration
        ├── 📂 bootstrap   # Kubernetes bootstrap config
        └── 📂 talos       # Talos configuration
```

## 🖥️ Hardware

| Name   | Device                    | CPU             | RAM            | Storage          | Purpose           |
|--------|---------------------------|-----------------|----------------|------------------|-------------------|
| Abel   | CWWK 6 LAN Port           | Intel i3-N305   | 48 GB DDR5     | -                | Control-plane     |
| Euclid | ASUS ExpertCenter PN42    | Intel N100      | 32 GB DDR4     | -                | Control-plane     |
| Cantor | ASUS PRIME N100I-D D4     | Intel N100      | 32 GB DDR4     | 5x8TB HDD RaidZ2 | NAS/Control-plane |
| Gauss  | Dell Precision Tower 5810 | Xeon E5-1650 v3 | 64 GB DDR4 ECC | 14 TB HDD        | Compute           |

## 🏗️ Work in Progress

- [ ] External DNS
- [ ] Use BGP with Cilium and UniFi
- [ ] Hajimari dashboard
- [ ] Podcast client
- [ ] Immich for photos
- [ ] Nextcloud for files
- [ ] Self-hosted git-solution (Gitea, GitLab, etc.)

## 👷‍ Future Projects

- [ ] Explore Kanidm as an identity management platform
- [ ] Explore other database operators
- [ ] Implement LGTM-stack for monitoring
- [ ] Local LLM
- [ ] Dynamic Resource Allocation for GPU
- [ ] Cilium mTLS & SPIFFE/SPIRE
- [ ] Ceph for distributed storage
- [ ] OPNSense/pfSense/OpenWRT
