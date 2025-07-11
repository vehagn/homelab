# Google Cloud Storage

## Prerequisites

Google Cloud Platform project with an active Billing Account.

## Getting started

1. Install `gcloud` — Instructions: https://cloud.google.com/sdk/docs/install-sdk
2. Run `gcloud init`
3. Authenticate `gcloud auth application-default login`

Before initialising, disable the GCS backend in `providers.tofu` (by e.g. commenting it out) since we can't store the
state in something that doesn't exist yet.
