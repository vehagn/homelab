resource "google_service_account" "tofu_dev_sa" {
  account_id   = "tofu-dev-sa"
  display_name = "Tofu Dev Service Account"
  description  = "Service account for development tasks using Tofu"
}

# Bucket names must be globally unique.
resource "google_storage_bucket" "tofu_remote_state" {
  name          = var.bucket_name
  location      = var.gcp.region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  # `force_destroy = true` must be applied before removing bucket
  force_destroy = true

  # Add a lifecycle rule to delete noncurrent versions after 90 days
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      # Delete noncurrent versions older than 90 days
      age = 30
      # Keep up to 100 newer versions
      num_newer_versions = 100
      # Apply this rule to noncurrent versions
      with_state = "ARCHIVED"
    }
  }
}

# This grants the tofu-dev_sa service account administrative permissions over objects in the bucket.
resource "google_storage_bucket_iam_member" "tofu_remote_state_object_admin" {
  bucket = google_storage_bucket.tofu_remote_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.tofu_dev_sa.email}"
}
