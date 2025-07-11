variable "email_routing_addresses" {
  description = "List of destination email addresses for routing"
  type        = list(string)
  default     = []
}

variable "email_routing_rules" {
  description = "Map of source email addresses to destination email addresses"
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([
      for dest_email in values(var.email_routing_rules) :
      contains(var.email_routing_addresses, dest_email)
    ])
    error_message = "All destination emails in 'email_routing_rules' must be present in the 'email_routing_addresses' list."
  }
}

variable "email_options" {
  description = "Email options"
  type        = string
  validation {
    condition = (
      can(jsondecode(var.email_options)) &&
      (
        try(jsondecode(var.email_options).default_email_address, null) == null ||
        contains(var.email_routing_addresses, jsondecode(var.email_options).default_email_address)
      )
    )
    error_message = "The 'email_options' must be a valid JSON string. If it contains a 'default_email_address', that address must be listed in 'email_routing_addresses'."
  }
}

variable "email_secret_mapping" {
  description = "Email secret mapping"
  type        = string
  validation {
    condition = (
      # First, ensure the variable is a valid JSON object.
      can(jsondecode(var.email_secret_mapping)) &&
      # If it is, then perform the validation on the decoded map.
      alltrue([
        for dest_email in values(jsondecode(var.email_secret_mapping)) :
        contains(var.email_routing_addresses, dest_email)
      ])
    )
    error_message = "The 'email_secret_mapping' must be a valid JSON string, and all its destination emails must be present in the 'email_routing_addresses' list."
  }
}
