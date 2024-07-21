# Manual bootstrap

## CRDs

Gateway API

```shell
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/experimental-install.yaml
```

## Cilium

```shell
kubectl kustomize --enable-helm infra/network/cilium | kubectl apply -f -
```

## Sealed-secrets

```shell
kustomize build --enable-helm infra/controllers/sealed-secrets | kubectl apply -f -
```

## Proxmox CSI Plugin

```shell
kustomize build --enable-helm infra/storage/proxmox-csi | kubectl apply -f -
```

```shell
kubectl get csistoragecapacities -ocustom-columns=CLASS:.storageClassName,AVAIL:.capacity,ZONE:.nodeTopology.matchLabels -A
```

## Argo CD

```shell
kustomize build --enable-helm infra/controllers/argocd | kubectl apply -f -
```

```shell
kubectl -n argocd get secret argocd-initial-admin-secret -ojson | jq -r ' .data.password | @base64d'
```

```shell
kubectl kustomize infra | kubectl apply -f -
```

# SBOM

* [x] Cilium
* [] Hubble
* [x] Argo CD
* [x] Proxmox CSI Plugin
* [x] Cert-manager
* [X] Gateway
* [] CNPG
* [] Authentication (Keycloak, Authentik, ...)

# CRDs

* [] Gateway
* [] Argo CD
* [] Sealed-secrets

# TODO

* [] Remotely managed cloudflared tunnel
* [] Keycloak
* [] Argo CD sync-wave

```shell
commonAnnotations:
    argocd.argoproj.io/sync-wave: "-1"
```

CNPG - Cloud Native PostGresSQL