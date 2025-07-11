# 1. Fetch latest release data from GitHub API
data "http" "github_latest_release" {
  url = "https://api.github.com/repos/CutTheCrapTech/email-gateway-cloudflare/releases/latest"

  # GitHub API may require this header
  request_headers = {
    Accept = "application/vnd.github.v3+json"
  }
}

# 2. Parse the JSON response and extract the tag name (version)
locals {
  latest_version = jsondecode(data.http.github_latest_release.response_body).tag_name
}
