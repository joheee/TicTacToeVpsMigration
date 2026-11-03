variable "project" {
  description = "Name prefix for resources."
  type        = string
  default     = "tictactoe"
}

variable "environment" {
  description = "Environment name (prod or dev); also decides the DigitalOcean project environment."
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["prod", "dev"], var.environment)
    error_message = "environment must be prod or dev."
  }
}

variable "region" {
  description = "DigitalOcean region for the Droplet, VPC, reserved IP and Space. sgp1 is the closest to Indonesia."
  type        = string
  default     = "sgp1"
}

variable "vpc_cidr" {
  description = "CIDR of the VPC."
  type        = string
  default     = "10.10.0.0/24"
}

variable "droplet_size" {
  description = "Droplet size slug. s-1vcpu-2gb is about $12 a month."
  type        = string
  default     = "s-1vcpu-2gb"
}

variable "droplet_image" {
  description = "Droplet image slug (Ubuntu LTS)."
  type        = string
  default     = "ubuntu-24-04-x64"
}

variable "admin_ssh_public_key" {
  description = "Public key registered with DigitalOcean for the Droplet (root login is disabled by cloud-init)."
  type        = string

  validation {
    condition     = can(regex("^ssh-", var.admin_ssh_public_key))
    error_message = "admin_ssh_public_key must be an OpenSSH public key (ssh-ed25519 ... or ssh-rsa ...)."
  }
}

variable "deploy_ssh_public_keys" {
  description = "Public keys allowed to log in as the deploy user: your own key and the CI key."
  type        = list(string)

  validation {
    condition     = length(var.deploy_ssh_public_keys) > 0
    error_message = "Provide at least one public key for the deploy user."
  }
}

variable "app_hostname" {
  description = "Public hostname of the app. Use the vps. rehearsal host first and switch to the real one at cutover."
  type        = string
  default     = "vps.tictactoe.johe.my.id"
}

variable "create_backup_bucket" {
  description = "Create the Spaces backup bucket ($5 a month minimum). Set false for cheap test runs."
  type        = bool
  default     = true
}

variable "backup_bucket_name" {
  description = "Name of the Spaces bucket for nightly pg_dump files."
  type        = string
  default     = "tictactoe-prod-backups"
}

variable "backup_retention_days" {
  description = "Days before backup objects expire."
  type        = number
  default     = 7
}

variable "backup_bucket_force_destroy" {
  description = "Allow destroying the bucket while it still holds objects. Leave false once real backups exist."
  type        = bool
  default     = false
}
