variable "create" {
  description = "Create the bucket. False skips it (Spaces costs $5 a month)."
  type        = bool
}

variable "name" {
  description = "Bucket name, unique within the region."
  type        = string
}

variable "region" {
  description = "DigitalOcean region of the bucket."
  type        = string
}

variable "retention_days" {
  description = "Days before objects expire."
  type        = number
}

variable "force_destroy" {
  description = "Allow destroying the bucket while it still holds objects."
  type        = bool
}
