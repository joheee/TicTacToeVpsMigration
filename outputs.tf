# Contract with joheee/TicTacToeCICD: these names map to its GitHub Actions
# variables (DO_*). Do not rename or remove them.

output "droplet_ipv4" {
  description = "Reserved IP the DNS record points at (DO_DROPLET_IP)."
  value       = module.compute.reserved_ip
}

# Kept for compatibility with TicTacToeCICD (DO_TAILSCALE_HOST). Tailscale is no
# longer used: SSH is public and key-only, so this now holds the reserved IP the
# deploy workflow connects to. Same value as ssh_host.
output "tailscale_hostname" {
  description = "Host the deploy workflow SSHes to (DO_TAILSCALE_HOST). Now the reserved IP; kept for the contract."
  value       = module.compute.reserved_ip
}

output "ssh_host" {
  description = "Host to SSH to as the deploy user. Prefer this over tailscale_hostname in new code."
  value       = module.compute.reserved_ip
}

output "deploy_user" {
  description = "Non-root user the deploy runs as (DO_DEPLOY_USER)."
  value       = local.deploy_user
}

output "app_url" {
  description = "Public URL for the smoke test (DO_APP_URL)."
  value       = "https://${var.app_hostname}"
}

output "backup_bucket" {
  description = "Spaces bucket for nightly pg_dump files, empty when not created (DO_BACKUP_BUCKET)."
  value       = module.storage.bucket_name
}

output "spaces_endpoint" {
  description = "S3-compatible endpoint for that bucket (DO_SPACES_ENDPOINT)."
  value       = module.storage.endpoint
}
