variable "name" {
  description = "Name prefix, for example tictactoe-prod."
  type        = string
}

variable "region" {
  description = "DigitalOcean region of the VPC."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR of the VPC."
  type        = string
}
