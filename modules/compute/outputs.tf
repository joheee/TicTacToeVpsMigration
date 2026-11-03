output "droplet_id" {
  description = "ID of the Droplet."
  value       = digitalocean_droplet.this.id
}

output "droplet_urn" {
  description = "URN of the Droplet, for the project."
  value       = digitalocean_droplet.this.urn
}

output "reserved_ip" {
  description = "Reserved IPv4 address attached to the Droplet."
  value       = digitalocean_reserved_ip.this.ip_address
}

output "reserved_ip_urn" {
  description = "URN of the reserved IP, for the project."
  value       = digitalocean_reserved_ip.this.urn
}
