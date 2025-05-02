# Google Cloud Storage

Example configuration for creating [Google Cloud Storage](https://cloud.google.com/storage) bucket for storing an
encrypted Tofu state in.

## Prerequisites

Google Cloud Platform project with an active Billing Account.

## Getting started

1. Install `gcloud` — Instructions: https://cloud.google.com/sdk/docs/install-sdk
2. Run `gcloud init`
3. Authenticate using `gcloud auth application-default login`

Before initialising, disable the GCS backend in `providers.tofu` (by e.g. commenting it out) since we can't store the
state in something that doesn't exist yet.

After the initial `tofy apply` to create the bucket, the state can be migrated by adding

```terraform
backend "gcs" {
  bucket = var.bucket_name
  prefix = var.state_prefix
}
```

back in and running

```shell
tofu init -migrate-state
```

to migrate the state to the remote GCS bucket.