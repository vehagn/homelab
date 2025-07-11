## Overview

This OpenTofu module automates the setup of a sophisticated email forwarding system using Cloudflare Email Routing and the open-source [email-gateway-cloudflare](https://github.com/CutTheCrapTech/email-gateway-cloudflare) worker. This setup provides a robust solution for managing both simple email forwarding and advanced, secure email aliasing.

## The `email-gateway-cloudflare` Worker

The core of the dynamic email forwarding is the `email-gateway-cloudflare` worker. This worker provides several key features:

- **Secure Email Forwarding**: The worker uses HMAC-based email aliases to cryptographically verify incoming emails. This prevents spammers and unauthorized senders from using your domain and flooding your inbox, a common problem with traditional catch-all addresses.
- **Dynamic Alias Generation**: You can generate secure, private email aliases on the fly for different services. This helps protect your real email address and track where spam is coming from.
- **Easy Alias Creation**: The open-source [browser extensions](https://github.com/CutTheCrapTech/email-alias-extensions) make it easy to generate these secure aliases directly in your browser.
- **Future-Improvements**: The project aims to integrate the [email-sanitizer](https://github.com/CutTheCrapTech/email-scrubber-core) library to strip tracking pixels and clean URLs from incoming emails. This feature is pending support for email body modification in Cloudflare Workers.

## Key Resources

- **`cloudflare_email_routing_address`**: Creates the destination email addresses where emails will be forwarded. **Note:** These addresses must be manually verified in the Cloudflare dashboard before they can be used.
- **`cloudflare_email_routing_rule`**: Defines static forwarding rules that map a source email address to a destination address.
- **`cloudflare_email_routing_catch_all`**: Configures a catch-all rule that forwards any email that doesn't match a static rule to the `email-gateway` worker.
- **`cloudflare_worker_script`**: Deploys the `email-gateway` worker, which enables dynamic and private email forwarding. The worker is configured with environment variables and secrets for customization.
- **`http` data source**: Dynamically fetches the latest version of the `email-gateway` worker script from the official GitHub repository, ensuring you are always running the latest version.

## Prerequisites

Before applying this module, you must complete the following steps in your Cloudflare dashboard:

1.  **Configure DNS for Email Routing**: Navigate to your zone's "Email Routing" settings and follow the instructions to add the required MX and TXT records to your DNS. This is a one-time setup that enables Cloudflare to handle your domain's email.
2.  **Verify Destination Addresses**: Any email address you intend to use as a destination for forwarding must be manually verified. You can do this in the "Email Routing" settings of your Cloudflare dashboard.

## Instructions

### Environment Variables

Ensure the following environment variables are set in your execution environment:

- `TF_VAR_cloudflare_account_id` - set it in infisical manually
- `TF_VAR_cloudflare_zone_id` - set it in infisical manually
- `TF_VAR_cloudflare_email_tofu_token` - automatically set in the devcontainer by [cloudflare account tokens](../account-tokens/cf/README.md).
- `TF_VAR_cloudflare_r2_tofu_access_key` - automatically set in the devcontainer by [cloudflare remote state](../../remote-state/cf/README.md).
- `TF_VAR_cloudflare_r2_tofu_access_secret` - automatically set in the devcontainer by [cloudflare remote state](../../remote-state/cf/README.md).
- `TF_VAR_bucket_name` - automatically set in the devcontainer when set in the `.env` file in the root folder.
- `TF_VAR_branch_env`- automatically set in the devcontainer base on the current branch.
- `TF_VAR_tofu_encryption_passphrase` - set it in infisical manually
- `TF_VAR_email_options` - Detailed docs on how to set these variables can be found in the [email-gateway-cloudflare](https://github.com/CutTheCrapTech/email-gateway-cloudflare).
- `TF_VAR_email_secret_mapping` - Detailed docs on how to set these variables can be found in the [email-gateway-cloudflare](https://github.com/CutTheCrapTech/email-gateway-cloudflare).
- `TF_VAR_email_routing_addresses` - destination addresses - example: `["x@gmail.com", "y@gmail.com"]`
- `TF_VAR_email_routing_rules` - routing rules for non catch-all forwarding - example: `{"a@your-domain.com": "x@gmail.com", "b@your-domain.com": "y@gmail.com"}`
- Note: You might need to run `source ~/.zshrc` in your devcontainer to ensure some of environment variables are loaded correctly after they are automatically set up in Infisical for the first time by remote state / account tokens.

### Execution

Once the prerequisites are met and the environment variables are set, you can apply the configuration:

```bash
# Initialize tofu
tofu init

# Run tofu apply to create the email routing rules and worker
tofu apply
```

## Known Issues

### Perpetual Diff in Worker Bindings

Due to the way the Cloudflare Terraform provider handles `secret_text` bindings for workers, you may notice a perpetual "in-place update" for the `cloudflare_workers_script.email_gateway_worker` resource in your `tofu plan` output. The provider cannot read the secret's value back from Cloudflare, so it conservatively proposes an update on every plan to ensure the secret is correctly set.

This is expected and harmless. The plan will simply re-apply the same secret value. It is a known inconvenience of the provider's design, and you can safely proceed with the apply.
