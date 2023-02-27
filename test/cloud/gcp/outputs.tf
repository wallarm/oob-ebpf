output "name" {
  value = local.name
}
output "region" {
  value = local.region
}

output "zone" {
  value = local.zone
}

output "id" {
  value = google_container_cluster.main.id
}

output "engine_version" {
  value = data.google_container_engine_versions.main.latest_master_version
}

output "image_type" {
  value = local.image_type
}