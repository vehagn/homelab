variable "email_routing_addresses" {
  description = "List of destination email addresses for routing"
  type        = list(string)
  default     = []
  sensitive   = true
}

variable "email_routing_rules" {
  description = "Map of source email addresses to destination email addresses"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "email_options" {
  description = "Email options"
  type        = string
}

variable "email_secret_mapping" {
  description = "Email secret mapping"
  type        = string
  sensitive   = true
}
