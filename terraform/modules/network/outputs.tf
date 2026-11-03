output "vpc_id" {
  description = "ID of the VPC."
  value       = digitalocean_vpc.this.id
}

output "droplet_tag" {
  description = "Tag that attaches a Droplet to the firewall."
  value       = digitalocean_tag.droplet.name
}
