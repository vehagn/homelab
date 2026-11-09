# Kubernetes Tofu

Read [Talos Kubernetes on Proxmox using OpenTofu](https://blog.stonegarden.dev/articles/2024/08/talos-proxmox-tofu/) for
a more thorough explanation of how everything works.

## Install pre-requisites - Pre-installed in devContainer

1. [tofu](https://opentofu.org/docs/intro/install/)
2. [talosctl](https://www.talos.dev/v1.9/talos-guides/install/talosctl/)
3. [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

## Initialize tofu

One cluster/state per branch.

1. Setup and initialize [remote backend](BACKEND.md).
1. Keep the environment populated with [required secrets](BACKEND.md) when running `tofu plan/apply`.

## Sealed-secrets

Generate certificate

```shell
openssl req -x509 -days 365 -nodes -newkey rsa:4096 -keyout sealed-secrets.key -out sealed-secrets.crt -subj "/CN=sealed-secret/O=sealed-secret"
```

## Kubernetes

Output `kubeconfig`

```shell
tofu output -raw kube_config
```

## Talos

Output `talosconfig`

```shell
tofu output -raw talos_config
```

## Upgrading Talos and Kubernetes

Follow these [instructions](UPGRADE.md).

## Reuse machine secrets

```shell
tofu state rm module.talos.talos_machine_secrets.this
tofu import module.talos.talos_machine_secrets.this output/talos-machine-secrets.yaml
tofu apply --refresh=false
```
