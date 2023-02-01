terraform {
  required_providers {
    google = {
      version = "4.49.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.0.0"
    }
  }
  backend "gcs" {}
}

provider "google" {
  region  = local.region
  zone    = local.zone
}