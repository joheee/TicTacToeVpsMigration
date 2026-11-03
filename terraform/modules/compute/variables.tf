variable "name" {
  description = "Droplet name, for example tictactoe-prod."
  type        = string
}

variable "region" {
  description = "DigitalOcean region of the Droplet and reserved IP."
  type        = string
}

variable "size" {
  description = "Droplet size slug."
  type        = string
}

variable "image" {
  description = "Droplet image slug."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC the Droplet joins."
  type        = string
}

variable "tags" {
  description = "Tags on the Droplet; the firewall matches on them."
  type        = list(string)
}

variable "admin_ssh_public_key" {
  description = "Public key registered with DigitalOcean for the Droplet."
  type        = string
}

variable "user_data" {
  description = "Rendered cloud-init user data."
  type        = string
  sensitive   = true
}
