resource "cloudflare_zero_trust_gateway_policy" "block_malware" {
  account_id = var.cloudflare_account_id

  name        = "Block malware"
  description = "Block known threats based on Cloudflare's threat intelligence"

  enabled    = true
  precedence = 10

  # Block all security risks
  filters = ["dns"]
  traffic = "any(dns.security_category[*] in {178 80 83 176 175 117 131 134 151 153 68})"
  action  = "block"

  rule_settings = {
    block_page_enabled = true
  }
}
