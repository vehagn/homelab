output "tofu_dev_service_account_email" {
  description = "The email of the service account that GitHub Actions will impersonate. Use this for the GCP_SERVICE_ACCOUNT_EMAIL GitHub secret."
  value       = module.gcs.tofu_service_account.email
}
