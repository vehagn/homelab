# Kubernetes Tofu

## Install pre-requisites
1. [tofu](https://opentofu.org/docs/intro/install/)
1. [talosctl](https://www.talos.dev/v1.9/talos-guides/install/talosctl/)
1. [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

## Initialize tofu
```shell
tofu init
```

## Proxmox

### Environment variable

```shell
export TF_VAR_proxmox_api_token="<YOUR_API_TOKEN>"
```

### Optional External Secrets Manager / Other methods

**Bitwarden Secrets Manager** - Name your secret TF_VAR_proxmox_api_token in bws.
```shell
bws run -- tofu ...
```
Note: By default the shell is sh. Change with --shell if required.


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
[Upgrade](https://blog.stonegarden.dev/articles/2024/08/talos-proxmox-tofu/#upgrading-the-cluster) talos nodes one by one.
1. Set talos_image.auto.tfvars -> image -> update_version to the required update version.
1. Set talos_cluster.auto.tfvars -> talos_cluster_config -> kubernetes_version to the required kubernetes version.
1. Set talos_nodes.auto.tfvars -> talos_nodes -> $node_1 -> update = true and run tofu apply.
1. Set talos_nodes.auto.tfvars -> talos_nodes -> $node_2 -> update = true, leave the previous nodes update = true and run tofu apply.
1. Set talos_nodes.auto.tfvars -> talos_nodes -> $node_3 -> update = true, leave the previous nodes update = true and run tofu apply.
1. ...
1. Set talos_nodes.auto.tfvars -> talos_nodes -> $node_n -> update = true, leave the previous nodes update = true and run tofu apply.
1. After upgrading all nodes, Set talos_image.auto.tfvars -> image -> version to match the update version and set update = false for all nodes.

## Upgrading Talos Schematic

1. Create a new schematic file.
1. Same process as above instead of image.version and image.update_version, change image.schematic and image.update_schematic, in talos_image.auto.tfvars.

## Upgrading Kubernetes Only

Dry Run
```shell
sh upgrade-k8s.sh $CONTROLPLANE_NODE_IP --dry-run     # For testing
```

Upgrade
```shell
sh upgrade-k8s.sh $CONTROLPLANE_NODE_IP
```
