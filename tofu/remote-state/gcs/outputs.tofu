# --- Outputs for Workload Identity Federation ---

output "workload_identity_provider_name" {
  description = "The full resource name of the Workload Identity Provider for GitHub Actions. Use this for the GCP_WORKLOAD_IDENTITY_PROVIDER GitHub secret."
  value       = google_iam_workload_identity_pool_provider.github_provider.name
  # Example output: projects/YOUR_PROJECT_NUMBER/locations/global/workloadIdentityPools/YOUR_POOL_ID/providers/YOUR_PROVIDER_ID
}

output "tofu_dev_service_account_email" {
  description = "The email of the service account that GitHub Actions will impersonate. Use this for the GCP_SERVICE_ACCOUNT_EMAIL GitHub secret."
  value       = google_service_account.tofu_dev_sa.email
}
