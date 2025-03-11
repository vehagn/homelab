# Kubernetes Tofu

## Install pre-requisites
1. [tofu](https://opentofu.org/docs/intro/install/)
1. [talosctl](https://www.talos.dev/v1.9/talos-guides/install/talosctl/)
1. [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

## Usage

### Initialize tofu
```shell
tofu init
```

### Change required config

Change the required config in the folder ../config/default/

### Populate Secrets

1. Create a Proxmox API token
1. Create config file / environment variables / secret manager as below

#### Config File
Copy secrets template and populate secrets.auto.tfvars with required secrets
```shell
cp ../secrets/default/proxmox.auto.tfvars.template ../secrets/default/proxmox.auto.tfvars
```

#### Environment Variables

Set the required environment variables
For Example
```shell
export TF_VAR_proxmox_api_token="Your Proxmox API Token"
```

#### Secret Manager

##### Bitwarden secrets manager

1. [Install bws](https://bitwarden.com/help/secrets-manager-cli/#download-and-install).
1. On macOS, as of 1.0.0, copy bws executable to /usr/local/bin.
1. [Create secrets and access token on bws](https://bitwarden.com/help/secrets-manager-quick-start/). For example name the proxmox token, TF_VAR_proxmox_api_token.
1. [Set bws Access token environment variable](https://bitwarden.com/help/secrets-manager-cli/#authentication).
1. Use bws run (as below) / Github Actions as necessary.


### Create a talos cluster

Create certificates for Sealed secrets if required. Else set create_sealed_secret_certificates = false in ../config/default/talos.auto.tfvars.
```shell
mkdir -p ./bootstrap/sealed-secrets/certificate/
cd ./bootstrap/sealed-secrets/certificate/
openssl req -x509 -days 365 -nodes -newkey rsa:4096 -keyout sealed-secrets.key -out sealed-secrets.crt -subj "/CN=sealed-secret/O=sealed-secret"
cd -
```

#### Talos apply with secrets from file
```shell
tofu apply -var-file=../config/default/proxmox.auto.tfvars -var-file=../config/default/talos.auto.tfvars -var-file=../secrets/default/proxmox.auto.tfvars
```

#### Talos apply with secrets from environment
```shell
tofu apply -var-file=../config/default/proxmox.auto.tfvars -var-file=../config/default/talos.auto.tfvars
```

#### Talos apply with secrets from bitwarden secrets manager
```shell
bws run -- tofu apply -var-file=../config/default/proxmox.auto.tfvars -var-file=../config/default/talos.auto.tfvars
```
Note: Default shell is sh. Change with bws run --shell fish, if necessary. Also rename variables, according to your stategy using an export or use projects.

## Upgrading Talos and Kubernetes
Upgrade talos nodes one by one. CONFIG_FILE==../config/default/talos.auto.tfvars
1. Set CONFIG_FILE -> image -> update_version to the required update version.
1. Set CONFIG_FILE -> cluster_nodes -> $node_1 -> update = true and run tofu apply.
1. Set CONFIG_FILE -> cluster_nodes -> $node_2 -> update = true, leave the previous nodes update = true and run tofu apply.
1. Set CONFIG_FILE -> cluster_nodes -> $node_3 -> update = true, leave the previous nodes update = true and run tofu apply.
1. ...
1. Set CONFIG_FILE -> cluster_nodes -> $node_n -> update = true, leave the previous nodes update = true and run tofu apply.
1. After upgrading all nodes, Set CONFIG_FILE -> image -> version to match the update version and set update = false for all nodes.

## Upgrading Talos Schematic

1. Create a new schematic file.
1. Same process as above instead of image.version and image.update_version, change image.schematic and image.update_schematic.

## Upgrading Kubernetes Only

Dry Run
```shell
sh upgrade-k8s.sh $CONTROLPLANE_NODE_IP --dry-run     # For testing
```

Upgrade
```shell
sh upgrade-k8s.sh $CONTROLPLANE_NODE_IP
```
