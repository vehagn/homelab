## Overview

This OpenTofu module is responsible for creating and managing specific, scoped Cloudflare Account API Tokens. These tokens are designed for use in other OpenTofu modules and CI/CD pipelines to perform automated tasks within the Cloudflare ecosystem.

## Key Resources

- **Scoped API Tokens**: Creates dedicated tokens for:
  - **Zero Trust & DNS**: For programmatically managing Zero Trust policies, lists, and DNS records.
  - **Email & Workers**: For automating email routing rules and related Worker scripts.
- **Secrets Management with Infisical**: Securely stores the generated API tokens in a specified Infisical project and path for other modules and services to consume.

## Instructions

This module assumes a pre-existing and configured OpenTofu remote state backend. For detailed prerequisites and step-by-step instructions, please refer to [DOCS.md](./DOCS.md).
