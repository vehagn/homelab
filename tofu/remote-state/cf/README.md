## Overview

This OpenTofu module provisions the foundational infrastructure for managing OpenTofu state within Cloudflare R2. It automates the creation of the R2 bucket and generates the necessary S3-compatible access credentials for remote state storage.

## Key Resources

- **R2 Bucket for Tofu Remote State**: A Cloudflare R2 bucket with versioning and lifecycle rules for secure state storage.
- **S3-Compatible R2 Access Credentials**: Programmatically generated credentials (Access Key ID and Secret Access Key) for R2 access, securely stored in Infisical.
- **Secrets Management with Infisical**: Manages both input secrets (e.g., Cloudflare API token) and output secrets (e.g., R2 access credentials).
- **OpenTofu State Encryption**: Ensures the OpenTofu state file is encrypted at rest for enhanced security.

## Instructions

This module uses a two-phase approach for bootstrapping the remote state. For detailed instructions, including prerequisites and step-by-step guides, please refer to [DOCS.md](./DOCS.md).
