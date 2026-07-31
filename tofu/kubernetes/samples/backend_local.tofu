terraform {
  backend "local" {
    path = "${var.gcs_prefix_env}.tfstate"
  }
}
