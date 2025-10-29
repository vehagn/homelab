## Setup Environment

### Using infisical

1. Setup [gcloud cli](/DEVCONTAINER.md).
1. Setup TF_VAR_proxmox_api_token, TF_VAR_tofu_encryption_passphrase and save them to infisical.
1. Setup .env file in root folder and commit it to git.
1. Follow devcontainers docs [here](/DEVCONTAINER.md). If done properly, all secrets from infisical will be available in the container environment.

Note: By default all secrets in /tofu folder will be populated. /tofu_rw is the folder where secrets are written. Also checkout default branch to env mapping.

## Setup Backend

### Local

```shell
# Local Backend
cp samples/backend_local.tofu.sample ./backend.tofu
```

```shell
# Local Backend
tofu init
```

**Note: If your are using local backend with dev devcontainers and git repo, your state file will be deleted when the container is removed. So be very careful.**

### R2

1. Follow instructions in [Cloudflare R2](../remote_state/cf/README.md) to setup R2 bucket for remote state.

```shell
# R2 Backend
cp samples/backend_r2.tofu.sample ./backend.tofu
```

```shell
# Initialize tofu
tofu init
```

### GCS

1. Follow instructions in [Google Cloud](../state/gcs/README.md) to setup GCS bucket for remote state.

```shell
# GCS Backend
cp samples/backend_gcs.tofu.sample ./backend.tofu
```

```shell
# Initialize tofu
tofu init
```
