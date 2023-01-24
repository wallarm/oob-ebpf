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