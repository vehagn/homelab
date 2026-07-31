# Workload Identity Federation Configuration for GitHub Actions
wif_config = {
  github_owner          = "karteekiitg"                 # Replace with your github username / org name
  github_repository     = "homelab"                     # Replace with your GitHub repository name
  pool_id               = "gh-actions-pool"             # Choose a suitable ID for the WIF pool
  pool_display_name     = "GitHub Actions WIF Pool"     # Choose a display name for the pool
  provider_id           = "gh-actions-provider"         # Choose a suitable ID for the WIF provider
  provider_display_name = "GitHub Actions WIF Provider" # Choose a display name for the provider
}
