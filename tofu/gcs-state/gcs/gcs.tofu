resource "google_service_account" "tofu_dev_sa" {
  account_id   = "tofu-dev-sa"
  display_name = "Tofu Dev Service Account"
  description  = "Service account for development tasks using Tofu"
}

resource "google_service_account_iam_member" "tofu_dev_sa_token_creator" {
  for_each = toset(var.gcp_sa_dev_emails)
  service_account_id = google_service_account.tofu_dev_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "user:${each.value}"
}

# Bucket names must be globally unique.
resource "google_storage_bucket" "tofu_remote_state" {
  name          = var.bucket_name
  location      = var.region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  # Enable public access prevention for the bucket
  public_access_prevention = "enforced"

  versioning {
    enabled = true
  }

  # Add a lifecycle rule to delete noncurrent versions after 90 days
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30         # Delete noncurrent versions older than 90 days
      num_newer_versions = 100        # Keep up to 100 newer versions
      with_state = "ARCHIVED" # Apply this rule to noncurrent versions
    }
  }
}

# This grants the tofu-dev_sa service account administrative permissions over objects in the bucket.
resource "google_storage_bucket_iam_member" "tofu_remote_state_object_admin" {
  # Renamed the resource here
  bucket = google_storage_bucket.tofu_remote_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.tofu_dev_sa.email}"
}
