# Kubernetes Tofu

```shell
tofu output -raw kube_config
tofu output -raw talos_config
```

## Proxmox

Environment variable

```shell
export TF_VAR_proxmox_api_token="<YOUR_API_TOKEN>"
```

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