## Overview

This OpenTofu module is responsible for provisioning the foundational infrastructure for managing OpenTofu state within Google Cloud Platform (GCP) and enabling secure CI/CD operations via GitHub Actions.

## Key resources

- **GCS Bucket for Tofu Remote State**: Stores OpenTofu state files securely with versioning.
- **Service Account (`tofu-dev-sa`)**: Used by authorized users and GitHub Actions (via WIF) to access GCP resources, primarily the state bucket.
- **Secrets Management with Infisical**: Manages module-specific secrets (like WIF details) and references user-managed secrets (like encryption passphrase, SA user emails).

For detailed information on these resources, including manual setup of user-managed secrets, see [DOCS.md](./DOCS.md#key-resources).

## Workload Identity Federation for GitHub Actions

This module sets up Google Cloud Workload Identity Federation (WIF), allowing GitHub Actions to securely authenticate to GCP and access the state bucket without using long-lived keys. The necessary WIF details are managed and pushed to Infisical.

For a detailed explanation of WIF configuration and benefits, see [DOCS.md](./DOCS.md#workload-identity-federation-for-github-actions).

## Instructions

This section provides a quick overview of the manual steps required to set up the GCS state backend.

For detailed prerequisites and step-by-step instructions, including how to generate and store necessary secrets and configure local variables, please refer to [DOCS.md](./DOCS.md#instructions).
