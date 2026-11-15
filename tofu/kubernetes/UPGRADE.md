## Upgrading Talos
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
