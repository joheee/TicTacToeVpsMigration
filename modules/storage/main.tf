resource "digitalocean_spaces_bucket" "this" {
  count = var.create ? 1 : 0

  name          = var.name
  region        = var.region
  acl           = "private"
  force_destroy = var.force_destroy

  lifecycle_rule {
    id      = "expire-backups"
    enabled = true

    expiration {
      days = var.retention_days
    }
  }
}
