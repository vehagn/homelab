resource "cloudflare_email_routing_address" "email_routing_addresses" {
  for_each   = toset(var.email_routing_addresses)
  account_id = var.cloudflare_account_id
  email      = each.value
}

resource "cloudflare_email_routing_rule" "email_routing_rules" {
  for_each = var.email_routing_rules
  zone_id  = var.cloudflare_zone_id

  actions = [{
    type  = "forward"
    value = [each.value]
  }]

  matchers = [{
    type  = "literal"
    field = "to"
    value = each.key
  }]

  enabled  = true
  name     = "EmailRule_${substr(md5(each.key), 0, 8)}"
  priority = 0
}

resource "cloudflare_email_routing_catch_all" "email_routing_catch_all" {
  zone_id = var.cloudflare_zone_id
  actions = [{
    type  = "worker"
    value = ["email-gateway"]
  }]
  matchers = [{
    type = "all"
  }]
  enabled = true
  name    = "Catch-all rule."
}
