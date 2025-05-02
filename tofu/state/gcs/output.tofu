output "tofu_service_account" {
  value = {
    id    = google_service_account.tofu_dev_sa.id
    name  = google_service_account.tofu_dev_sa.name
    email = google_service_account.tofu_dev_sa.email
  }
}
