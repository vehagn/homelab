# 1. Fetch latest release data from GitHub API
data "http" "github_releases" {
  url = "https://api.github.com/repos/CutTheCrapTech/email-gateway-cloudflare/releases"

  # GitHub API may require this header
  request_headers = {
    Accept = "application/vnd.github.v3+json"
  }
}

# 2. Parse the JSON response and extract the tag name (version) for the correct package
locals {
  package_name   = "@email-gateway/cloudflare-worker"
  releases       = jsondecode(data.http.github_releases.response_body)
  worker_release = [for r in local.releases : r if startswith(r.tag_name, "${local.package_name}@")][0]
  latest_version = local.worker_release.tag_name
}
