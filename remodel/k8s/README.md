# Manual bootstrap

## Cilium

```shell
kubectl kustomize --enable-helm infra/network/cilium | kubectl apply -f -
```

## Sealed-secrets

```shell
kubectl kustomize --enable-helm infra/controllers/sealed-secrets | kubectl apply -f -
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
kubectl kustomize --enable-helm infra/controllers/argocd | kubectl apply -f -
```

```shell
kubectl -n argocd get secret argocd-initial-admin-secret -ojson | jq -r ' .data.password | @base64d'
```

```shell
kubectl kustomize --enable-helm infra/storage | kubectl apply -f -
```