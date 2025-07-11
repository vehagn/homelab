gcp = {
  project_id = "homelab-359819",
  region = "europe-west1"
}

gcp_sa_dev_emails = ["veghag@gmail.com"]

wif_config = {
  github_owner          = "vehagn"                 # Replace with your github username / org name
  github_repository     = "homelab"                     # Replace with your GitHub repository name
  pool_id               = "gh-actions-pool"             # Choose a suitable ID for the WIF pool
  pool_display_name     = "GitHub Actions WIF Pool"     # Choose a display name for the pool
  provider_id           = "gh-actions-provider"         # Choose a suitable ID for the WIF provider
  provider_display_name = "GitHub Actions WIF Provider" # Choose a display name for the provider
}
