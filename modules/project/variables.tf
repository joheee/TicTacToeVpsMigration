variable "name" {
  description = "Project name."
  type        = string
}

variable "environment" {
  description = "DigitalOcean project environment: Development, Staging or Production."
  type        = string
}

variable "resource_urns" {
  description = "URNs of the resources to group in the project."
  type        = list(string)
}
