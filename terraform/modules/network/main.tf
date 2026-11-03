resource "digitalocean_vpc" "this" {
  name     = "${var.name}-vpc"
  region   = var.region
  ip_range = var.vpc_cidr
}

# The firewall attaches to Droplets by tag, so it exists before the Droplet does.
resource "digitalocean_tag" "droplet" {
  name = var.name
}

# Inbound is HTTP and HTTPS only. There is no port 22: SSH goes over Tailscale,
# which only needs outbound traffic.
resource "digitalocean_firewall" "this" {
  name = "${var.name}-fw"
  tags = [digitalocean_tag.droplet.name]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Outbound is open: GHCR, Let's Encrypt, Spaces, apt and Tailscale need it.
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
