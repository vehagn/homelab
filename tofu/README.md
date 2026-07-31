# OpenTofu Infrastructure

This directory contains all the OpenTofu modules for managing the infrastructure of this homelab. The modules are designed to be applied in a specific order to ensure dependencies are met.

## Execution Order & Workflow

It is crucial to apply these modules in the following sequence:

### 1. Remote State Backend (Optional but Recommended)

Setting up a remote backend is the first step for managing state collaboratively and securely. If you do not set up a remote backend, OpenTofu will use a local state file by default. The `kubernetes` module contains samples for local(default), GCS, and R2 backends that can be adapted for other modules.

Choose one of the following options if you want to use remote state:

- **Cloudflare R2**: See the instructions in [`./remote-state/cf/README.md`](./remote-state/cf/README.md)
- **Google Cloud Storage (GCS)**: See the instructions in [`./remote-state/gcs/README.md`](./remote-state/gcs/README.md)

### 2. Cloudflare Account Tokens

**This is a prerequisite for all other Cloudflare modules.**

This module creates the scoped API tokens that are required to authenticate and authorize the other Cloudflare-related modules.

- **Instructions**: See [`./cloudflare/account-tokens/README.md`](./cloudflare/account-tokens/README.md)

### 3. Other Cloudlare Modules

Once the prerequisites are met, you can apply the other modules as needed. By default, all modules below are configured to use the Cloudflare R2 remote state backend. If you want to use a different remote backend, you will need to adjust the `backend.tofu` file in each module accordingly (for reference check [`Kubernetes`](./kubernetes/README.md)).

- **Cloudflare Adblock**: Manages Cloudflare Zero Trust Gateway DNS policies for ad and malware blocking.
  - **Instructions**: See [`./cloudflare/adblock/README.md`](./cloudflare/adblock/README.md)

- **Cloudflare Email Alias**: Configures a powerful and secure email forwarding system using Cloudflare Email Routing and a custom worker.
  - **Instructions**: See [`./cloudflare/email-alias/README.md`](./cloudflare/email-alias/README.md)

### 4. Kubernetes

- **Kubernetes**: Provisions the Kubernetes cluster on proxmox using talos. This module is flexible and supports local state, as well as GCS and R2 remote backends. You can find sample backend configurations within its directory.
  - **Instructions**: See [`./kubernetes/README.md`](./kubernetes/README.md)

### Suggestions (Opinionated)

I suggest you to use R2 remote state backend. It is the default for all new modules, except kubernetes. As most of us use cloudflare anyway, and has a generous 10GB free tier, I feel its a good default.

I also suggest using infisical. It is opensource and has a very generous free tier. All new modules, except Kubernetes, are configured to use infisical for secrets management by default. For Kubernetes module, infisical is optional, but recommended.
