locals {
  region  = "europe-west2"
  zone    = "europe-west2-a"
  version = replace(split("-", var.kube_version)[0], ".", "-")
  os      = lower(var.os)
  name    = "${var.name_prefix}-v${local.version}-${local.os}-run-${var.github_run_number}"
  image_type = local.os == "ubuntu" ? "UBUNTU_CONTAINERD" : "COS_CONTAINERD"

  tags = {
    Environment = "github-ci"
    Workflow    = "CI"
    Repository  = "oob-ebpf"
    RunNumber   = var.github_run_number
  }
}

data "google_container_engine_versions" "main" {
  provider       = google-beta
  location       = local.zone
  version_prefix = "${var.kube_version}."
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

  min_master_version = data.google_container_engine_versions.main.latest_master_version
  initial_node_count = var.node_count

  node_config {
    service_account = google_service_account.main.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    image_type = local.image_type
    machine_type = var.node_size
  }
}