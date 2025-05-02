variable "wif_config" {
  description = "Configuration for Workload Identity Federation with GitHub Actions."
  type = object({
    github_owner          = string
    github_repository     = string
    pool_id               = string
    pool_display_name     = string
    provider_id           = string
    provider_display_name = string
  })
}
