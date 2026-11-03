output "bucket_name" {
  description = "Bucket name, or an empty string when it was not created."
  value       = var.create ? digitalocean_spaces_bucket.this[0].name : ""
}

output "bucket_urn" {
  description = "Bucket URN for the project, or an empty string when it was not created."
  value       = var.create ? digitalocean_spaces_bucket.this[0].urn : ""
}

output "endpoint" {
  description = "S3-compatible endpoint for the region."
  value       = "https://${var.region}.digitaloceanspaces.com"
}
