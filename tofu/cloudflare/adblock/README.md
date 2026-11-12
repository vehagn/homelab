# Cloudflare Adblock & Malware DNS Filtering

Automated management of Cloudflare Zero Trust Gateway DNS policies for ad and malware blocking. This setup uses a combination of OpenTofu for core infrastructure resources and a Python script for managing dynamic adblock domain lists and their associated policy via the Cloudflare API.

## My Usage

I generally tend to avoid hosting piHole / AdGuard, as when they go down, we lose access to the internet. Setting HA is not quite straight forward. Also it mostly only covers home network, not mobile network.

Even if using piHole / AdGuard, you can use to set this DoH endpoint as upstream. So, I use this setup in the following way, after getting DoH endpoint / ipv6 address from cloudflare:

1.  On Browsers, android, ios, etc. i use the DoH endpoint to directly on top of using uBo and sponsorblock.
2.  My router only supports ipv4 addresses as dns servers. So I use 1.1.1.2 / 1.0.0.2 as dns servers to block malware by default. If your router / devices supports DoH or DoT by default, always use it instead of ipv4 / ipv6.
3.  If using cloudflare warp as your vpn / zerotrust setup, your devices are automatically protected by warp. I also use the ipv6 address as upstream for tailscale / netbird, so that I am also protected by default, when using these as my vpn / zerotrust.
4.  I use a secondary cloudflare account, using a cheap [1.111B class domain](https://gen.xyz/1111b).

## Overview

Enhances network security and user experience by filtering unwanted content at the DNS level using Cloudflare Gateway.

**Key Components & Functionality:**

1.  **`adblock_urls.txt`**:
    - Lists URLs of external ad/malware domain sources.
2.  **`chunk_adblock_lists.sh` (Shell Script)**:
    - Downloads, processes, and splits domains from `adblock_urls.txt` into chunk files for Cloudflare lists, handling limits and changes.
3.  **OpenTofu Configuration (`.tofu` files)**:
    - Manages core infrastructure resources like the backend, providers, variables, the malware policy, and the DNS location.
4.  **`manage_cloudflare_adblock.py` (Python Script)**:
    - Manages Cloudflare Zero Trust lists and the associated adblock policy dynamically via the API based on chunk files, using hash-based change detection.

For detailed descriptions of each component, see [DOCS.md](./DOCS.md).

## GitHub Action Automation (`cf_adblock.yaml`)

The update process is automated via a [GitHub Action](/.github/workflows/cf_adblock.yaml). It runs monthly on a schedule or can be triggered manually. The workflow prepares the domain lists using `chunk_adblock_lists.sh`, applies the OpenTofu configuration for static resources (like the DNS location and malware policy), and then runs the Python script (`manage_cloudflare_adblock.py`) to manage the dynamic adblock lists and the associated policy using the Cloudflare API and OpenTofu outputs (like the DNS Location ID).

For a detailed breakdown of the workflow steps, see [DOCS.md](./DOCS.md#github-action-automation).

## Required Inputs (Variables & Secrets)

Configure these securely. The GitHub Action fetches them via Infisical secrets automatically (surfaced as `TF_VAR_...` or regular environment variables). They must also be present in devcontainer.

- `TF_VAR_cloudflare_account_id`: Your Cloudflare Account ID for Zero Trust configurations (used by OpenTofu and the Python script).
- `TF_VAR_cloudflare_zero_trust_tofu_token`: Cloudflare API Token with necessary permissions for Zero Trust management (used by OpenTofu and the Python script). **Sensitive secret.** - Generated automatically via [account-tokens](../account-tokens/README.md)
- `TF_VAR_bucket_name`: GCS bucket name for OpenTofu remote state.
- `TF_VAR_tofu_encryption_passphrase`: Passphrase for OpenTofu state encryption. **Sensitive secret.**
- `TF_VAR_cloudflare_r2_tofu_access_key`: Cloudflare R2 access key for remote state. **Sensitive secret.** - Generated automatically via [remote-state/cf](../../remote-state/cf/README.md)
- `TF_VAR_cloudflare_r2_tofu_access_secret`: Cloudflare R2 access secret for remote state. **Sensitive secret.** - Generated automatically via [remote-state/cf](../../remote-state/cf/README.md)

## Manual Setup & Execution (Local Environment)

While the primary method for updating the lists and policy is the automated GitHub Action, you may need to run the process manually for testing, development, or initial setup in a local environment (like a devcontainer).

For detailed prerequisites, step-by-step instructions, and the command reference, please refer to [DOCS.md](./DOCS.md#manual-setup--execution-local-environment).

## Acknowledgements

This part of cloudflare ad-blocking was inspired by Marco Lancini's [blog post](https://blog.marcolancini.it/2022/blog-serverless-ad-blocking-with-cloudflare-gateway/) on serverless ad-blocking with Cloudflare Gateway.
