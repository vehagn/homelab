locals {
  # Get all list IDs from the adblock_domain_lists map of resources
  # cloudflare_zero_trust_list.adblock_domain_lists is now a map of resources because it uses for_each
  adblock_list_ids = [
    for list_object in values(cloudflare_zero_trust_list.adblock_domain_lists) : list_object.id
  ]

  # Format these IDs for use in the policy's traffic string.
  adblock_list_refs_for_policy = [
    for id in local.adblock_list_ids : format("$%s", replace(id, "-", ""))
  ]

  # Construct the traffic filter string.
  # If no lists are found/created, use a "no-match" condition like "1==0".
  adblock_ad_filter = length(local.adblock_list_refs_for_policy) > 0 ? join(" or ", formatlist("any(dns.domains[*] in %s)", local.adblock_list_refs_for_policy)) : "1==0"
}

resource "cloudflare_zero_trust_gateway_policy" "block_ads" {
  account_id = var.cloudflare_secondary_account_id

  name        = "Block Ads"
  description = "Block Ads domains"

  enabled    = true
  precedence = 11

  # Block domain belonging to lists (defined below)
  filters = ["dns"]
  action  = "block"
  traffic = local.adblock_ad_filter

  rule_settings = {
    block_page_enabled = false
  }
}

resource "cloudflare_zero_trust_gateway_policy" "block_malware" {
  account_id = var.cloudflare_secondary_account_id

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
