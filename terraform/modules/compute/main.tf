resource "digitalocean_ssh_key" "admin" {
  name       = "${var.name}-admin"
  public_key = var.admin_ssh_public_key
}

resource "digitalocean_droplet" "this" {
  name     = var.name
  region   = var.region
  size     = var.size
  image    = var.image
  vpc_uuid = var.vpc_id
  ssh_keys = [digitalocean_ssh_key.admin.fingerprint]
  tags     = var.tags

  user_data = var.user_data

  monitoring = true  # free metrics and alert policies
  backups    = false # paid add-on, not part of the plan
  ipv6       = false

  lifecycle {
    # Changing user_data or the image would replace the Droplet and wipe the
    # database volume on its disk. A cloud-init edit only applies to new Droplets.
    ignore_changes = [user_data, image]
  }
}

# Stable address for the DNS record; it survives a rebuild of the Droplet.
# It costs money when it is not assigned, so it is destroyed with everything else.
resource "digitalocean_reserved_ip" "this" {
  region = var.region
}

resource "digitalocean_reserved_ip_assignment" "this" {
  ip_address = digitalocean_reserved_ip.this.ip_address
  droplet_id = digitalocean_droplet.this.id
}
