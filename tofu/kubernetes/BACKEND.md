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
tofu init -backend-config="path=$(git rev-parse --abbrev-ref HEAD).tfstate"
```
**Note: If your are using local backend with dev devcontainers and git repo, your state file will be deleted when the container is removed. So be very careful.**

### GCS
1. Follow instructions in [Google Cloud](../gcs-state/README.md) to setup GCS bucket for remote state.

```shell
# GCS Backend
cp samples/backend_gcs.tofu ./backend.tofu
```

```shell
# Initialize tofu
tofu init -backend-config="bucket=<your_bucket_name>" -backend-config="prefix=kubernetes/$(git rev-parse --abbrev-ref HEAD)"
```

### Beta Notice

`Please treat GCS backend as beta and only use for air-gapped installations as of now. Will remove the beta tag after testing it in due course.`
