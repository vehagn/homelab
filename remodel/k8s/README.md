# Manual bootstrap

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
kubectl kustomize --enable-helm infra/storage/proxmox-csi | kubectl apply -f -
```

```shell
kubectl get csistoragecapacities -ocustom-columns=CLASS:.storageClassName,AVAIL:.capacity,ZONE:.nodeTopology.matchLabels -A
```

## Argo CD

```shell
kubeseal -oyaml --controller-namespace=sealed-secrets < argocd-docker-secret.yaml > infra/argocd/docker-helm-credentials.yaml
```

```shell
kubeseal -oyaml --controller-namespace=sealed-secrets < argocd-ghcr-secret.yaml > infra/argocd/ghcr-helm-credentials.yaml
```

```shell
kustomize build --enable-helm infra/argocd | kubectl apply -f -
```

```shell
kubectl -n argocd get secret argocd-initial-admin-secret -ojson | jq -r ' .data.password | @base64d'
```

```shell
kubectl kustomize --enable-helm infra/storage | kubectl apply -f -
```

```shell
kubectl kustomize --enable-helm infra/controllers | kubectl apply -f -
```

```shell
kubectl kustomize --enable-helm infra | kubectl apply -f -
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