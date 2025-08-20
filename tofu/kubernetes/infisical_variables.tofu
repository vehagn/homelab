variable "infisical_domain" {
  description = "Infisical Domain"
  type        = string
  default     = "https://app.infisical.com"
}

variable "infisical_client_id" {
  description = "Infisical Client ID"
  type        = string
  default     = null
}

variable "infisical_project_id" {
  description = "Infisical Project ID"
  type        = string
  default     = null
}

variable "infisical_rw_secrets_path" {
  description = "Infisical Client Secret"
  type        = string
  default     = "/tofu_rw"
}

variable "infisical_branch_env_mapping" {
  description = "Infisical Branch Environment Mapping"
  type        = map(string)
  default = {
    "main"    = "prod"
    "prod"    = "prod"
    "staging" = "staging"
    "dev"     = "dev"
  }
}

variable "infisical_client_secret" {
  description = "Infisical Client Secret"
  type        = string
  sensitive   = true
  default     = null
}
