# Fetch the worker script content from the URL
data "http" "email_gateway_worker_script" {
  url = "https://github.com/CutTheCrapTech/email-gateway-cloudflare/releases/download/${local.latest_version}/worker.js"
}

# Create the Cloudflare Worker script
resource "cloudflare_workers_script" "email_gateway_worker" {
  account_id  = var.cloudflare_account_id
  script_name = "email-gateway"
  content     = data.http.email_gateway_worker_script.response_body

  bindings = [
    {
      name = "EMAIL_SECRET_MAPPING"
      type = "secret_text"
      text = var.email_secret_mapping
    },
    {
      name = "EMAIL_OPTIONS"
      type = "plain_text"
      text = var.email_options
    }
  ]

  observability = {
    enabled            = true
    head_sampling_rate = 100
  }
}
