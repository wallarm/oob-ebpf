locals {
  region  = "europe-west2"
  zone    = "europe-west2-a"
  version = replace(split("-", var.kube_version)[0], ".", "-")
  name    = "${var.name_prefix}-v${local.version}-run-${var.github_run_number}"

  tags = {
    Environment = "github-ci"
    Workflow    = "CI"
    Repository  = "oob-ebpf"
    RunID       = var.github_run_id
    RunNumber   = var.github_run_number
  }
}

resource "google_compute_network" "main" {
  name                    = "${local.name}-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "main" {
  name          = "${local.name}-subnet"
  region        = local.region
  network       = google_compute_network.main.name
  ip_cidr_range = "10.10.0.0/24"
}

resource "random_string" "sa_suffix" {
  length           = 4
  special          = false
  lower            = true
  min_lower        = 4
}

resource "google_service_account" "main" {
  account_id   = "${var.name_prefix}-${random_string.sa_suffix.result}"
  display_name = local.name
}

resource "google_container_cluster" "main" {
  name       = local.name
  location   = local.zone
  network    = google_compute_network.main.name
  subnetwork = google_compute_subnetwork.main.name

  min_master_version = var.kube_version
  initial_node_count = var.node_count

  node_config {
    service_account = google_service_account.main.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}