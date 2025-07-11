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

- [Proxmox VE](https://www.proxmox.com/en/proxmox-virtual-environment): Server management and KVM hypervisor.
- [OpenTofu](https://opentofu.org/): Open source infrastructure as code tool.
- [DevContainers](https://containers.dev/): Container as a full-featured development environment.
- [Cilium](https://cilium.io/): eBPF-based Networking, Observability, Security.
- [Proxmox CSI Plugin](https://github.com/sergelogvinov/proxmox-csi-plugin): CSI driver for storage
- [Argo CD](https://argo-cd.readthedocs.io/en/stable/): Declarative, GitOps continuous delivery tool for Kubernetes.
- [Cloudflare ZeroTrust](https://developers.cloudflare.com/cloudflare-one/): Cloudflare ZeroTrust.
- [Infisical](https://infisical.com/): Open source secrets management.
- [Pocket ID](https://github.com/pocket-id/pocket-id): Open source authentication and authorization server
- [Gateway API](https://gateway-api.sigs.k8s.io/): Next generation of Kubernetes Ingress
- [NetBird](https://netbird.io/): Completely self hosted VPN solution
- [CloudNativePG](https://cloudnative-pg.io/): PostgreSQL database operator

## 🗃️ Folder Structure

```shell
.
├── 📂 docs                       # Documentation
├── 📂 k8s                        # Kubernetes manifests
│   ├── 📂 apps                  # Applications
│   ├── 📂 infra                 # Infrastructure components
│   └── 📂 sets                  # Bootstrapping ApplicationSets
└── 📂 tofu                       # Tofu configuration
    ├── 📂 home-assistant         # Home Assistant VM
    └── 📂 kubernetes             # Kubernetes VM configuration
        ├── 📂 bootstrap          # Kubernetes bootstrap config
        └── 📂 talos              # Talos configuration
    └── 📂 cloudflare             # Cloudflare configuration
        ├── 📂 account-tokens     # Scoped account tokens
        └── 📂 email-alias        # Email routing
        └── 📂 adblock            # AdBlock configuration
    └── 📂 remote-state           # Opentofu remote state management
        ├── 📂 cf                 # Cloudflare
        └── 📂 gcs                # Google cloud storage
```
