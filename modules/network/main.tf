resource "digitalocean_vpc" "this" {
  name     = "${var.name}-vpc"
  region   = var.region
  ip_range = var.vpc_cidr
}

# The firewall attaches to Droplets by tag, so it exists before the Droplet does.
resource "digitalocean_tag" "droplet" {
  name = var.name
}

# Inbound is HTTP, HTTPS and SSH. SSH is open to the internet because the deploy
# runs from GitHub-hosted runners, which have no fixed IP. It is protected by
# key-only login, no root, MaxAuthTries 3 and fail2ban (see cloud-init).
resource "digitalocean_firewall" "this" {
  name = "${var.name}-fw"
  tags = [digitalocean_tag.droplet.name]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

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

  # Outbound is open: GHCR, Let's Encrypt, Spaces, and apt need it.
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
