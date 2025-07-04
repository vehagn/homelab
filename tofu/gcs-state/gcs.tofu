# 1. Create a Service Account named tofu-dev-sa
resource "google_service_account" "tofu_dev_sa" {
  account_id   = "tofu-dev-sa"
  display_name = "Tofu Dev Service Account"
  description  = "Service account for development tasks using Tofu"
}

# 2. Grant users the roles/iam.serviceAccountTokenCreator role on the tofu_dev_sa service account
# This allows the specified users to impersonate the tofu-dev-sa service account.
# Using for_each to iterate over the list of user email addresses.
resource "google_service_account_iam_member" "tofu_dev_sa_token_creator" {
  # Use for_each to create an instance of this resource for each email in the list.
  # toset() is used to ensure a set of unique keys for for_each.
  for_each           = toset(jsondecode(var.gcp_sa_dev_emails))
  service_account_id = google_service_account.tofu_dev_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  # Use each.value to reference the current email address in the iteration.
  member = "user:${each.value}"
}

# 3. Create a GCS bucket
# Bucket names must be globally unique.
resource "google_storage_bucket" "tofu_remote_state" {
  name          = var.bucket_name
  location      = var.gcp_region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  # Enable public access prevention for the bucket
  public_access_prevention = "enforced"

  # Enable versioning for objects in the bucket
  versioning {
    enabled = true
  }

  # Add a lifecycle rule to delete noncurrent versions after 90 days
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age                = 30         # Delete noncurrent versions older than 90 days
      num_newer_versions = 100        # Keep up to 100 newer versions
      with_state         = "ARCHIVED" # Apply this rule to noncurrent versions
    }
  }
}

# 4. Add Storage Object Admin permission for this bucket for tofu-dev-sa
# This grants the tofu-dev_sa service account administrative permissions over objects in the bucket.
resource "google_storage_bucket_iam_member" "tofu_remote_state_object_admin" { # Renamed the resource here
  bucket = google_storage_bucket.tofu_remote_state.name                        # Updated reference here
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.tofu_dev_sa.email}"
}
