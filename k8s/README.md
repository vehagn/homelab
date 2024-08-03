# Manual bootstrap

## CRDs

Gateway API

```shell
kubectl apply -k infra/crds
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
kubectl apply -k infra
```

```shell
kubectl apply -k sets
```

# SBOM

* [x] Cilium
* [X] Hubble
* [x] Argo CD
* [x] Proxmox CSI Plugin
* [x] Cert-manager
* [X] Gateway
* [X] Authentication (Keycloak, Authentik, ...)
* [] CNPG - Cloud Native PostGresSQL

# CRDs

* [] Gateway
* [] Argo CD
* [] Sealed-secrets

# TODO

* [X] Remotely managed cloudflared tunnel
* [X] Keycloak
* [] Argo CD sync-wave

```shell
commonAnnotations:
    argocd.argoproj.io/sync-wave: "-1"
```
