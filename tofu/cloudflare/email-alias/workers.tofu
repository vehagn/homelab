# Fetch the worker script content from the URL
data "http" "email_gateway_worker_script" {
  url = "https://github.com/CutTheCrapTech/email-gateway-cloudflare/releases/download/${local.latest_version}/worker.js"
}

# Create the Cloudflare Worker script
resource "cloudflare_workers_script" "email_gateway_worker" {
  account_id         = var.cloudflare_account_id
  script_name        = "email-gateway-${var.branch_env}"
  content            = data.http.email_gateway_worker_script.response_body
  main_module        = "worker.js"
  compatibility_date = "2025-07-10"

  bindings = [
    # Bindings are ordered alphabetically to ensure a stable plan.
    {
      name = "EMAIL_OPTIONS"
      type = "plain_text"
      text = var.email_options
    },
    {
      name = "EMAIL_SECRET_MAPPING"
      type = "secret_text"
      text = var.email_secret_mapping
    }
  ]

  observability = {
    enabled            = true
    head_sampling_rate = 1
  }
}
