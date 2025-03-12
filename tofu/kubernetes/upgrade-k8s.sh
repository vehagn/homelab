# Usage: sh upgrade-k8s.sh <controlplane node> or sh upgrade-k8s.sh <controlplane node> --dry-run (for a dry run)
talosctl $2 --nodes $1 upgrade-k8s --to 1.32.0 # renovate: github-releases=kubernetes/kubernetes
