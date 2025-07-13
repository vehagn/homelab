## Overview

This OpenTofu module configures a powerful and secure email forwarding system using Cloudflare Email Routing and the open-source [email-gateway-cloudflare](https://github.com/CutTheCrapTech/email-gateway-cloudflare) worker. It enables both standard email forwarding and dynamic, secure, and private email alias generation.

## Key Features

- **Standard Email Forwarding**: Create simple, static rules to forward emails bound to custom addresses to designated destinations, using a mapping.
- **Secure Catch-all Worker**: Deploys a worker that acts as a catch-all, processing all emails that don't match a static rule. This worker uses HMAC-based email aliases to prevent spam and unauthorized use of your domain.
- **Dynamic Worker Versioning**: Automatically fetches and deploys the latest version of the email gateway worker from GitHub, ensuring you always have the latest features and security updates.
- **Easy Alias Generation**: Secure email aliases can be easily generated using the open-source [browser extensions](https://github.com/CutTheCrapTech/email-alias-extensions) for both [chrome](https://chromewebstore.google.com/detail/email-alias-generator/ghhkompkfhenihpidldalcocbfplkdgm) and [firefox](https://addons.mozilla.org/en-US/firefox/addon/email-alias-generator-hmac/).

## Prerequisites

- **DNS Configuration**: Before using this module, you must configure the DNS records for email routing in your Cloudflare dashboard. Follow the instructions in the Cloudflare dashboard to add the required MX and TXT records.
- **Destination Email Verification**: You must manually verify any destination email addresses in the Cloudflare dashboard before they can be used in routing rules.

## Instructions

For detailed prerequisites and step-by-step instructions, please refer to [DOCS.md](./DOCS.md).
