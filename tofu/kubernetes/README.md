# Kubernetes Tofu

Read [Talos Kubernetes on Proxmox using OpenTofu](https://blog.stonegarden.dev/articles/2024/08/talos-proxmox-tofu/) for
a more thorough explanation of how everything works.

## Install pre-requisites

1. [tofu](https://opentofu.org/docs/intro/install/)
2. [talosctl](https://www.talos.dev/v1.9/talos-guides/install/talosctl/)
3. [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

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

Note: By default, the shell is sh. Change with --shell if required.

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

[Upgrade](https://blog.stonegarden.dev/articles/2024/08/talos-proxmox-tofu/#upgrading-the-cluster) talos nodes one by
one.

1. Set talos_image.auto.tfvars -> image -> update_version to the required update version.
2. Set talos_cluster.auto.tfvars -> talos_cluster_config -> kubernetes_version to the required kubernetes version.
3. Set talos_nodes.auto.tfvars -> talos_nodes -> $node_1 -> update = true and run tofu apply.
4. Set talos_nodes.auto.tfvars -> talos_nodes -> $node_2 -> update = true, leave the previous nodes update = true and
   run tofu apply.
5. Set talos_nodes.auto.tfvars -> talos_nodes -> $node_3 -> update = true, leave the previous nodes update = true and
   run tofu apply.
6. ...
7. Set talos_nodes.auto.tfvars -> talos_nodes -> $node_n -> update = true, leave the previous nodes update = true and
   run tofu apply.
8. After upgrading all nodes, Set talos_image.auto.tfvars -> image -> version to match the update version and set
   update = false for all nodes.

## Upgrading Talos Schematic

1. Create a new schematic file.
2. Same process as above instead of `image.version` and `image.update_version`, change `image.schematic` and
   `image.update_schematic`, in `talos_image.auto.tfvars`.

## Reuse machine secrets

```shell
tofu state rm module.talos.talos_machine_secrets.this
tofu import module.talos.talos_machine_secrets.this output/talos-machine-secrets.yaml
tofu apply --refresh=false
```