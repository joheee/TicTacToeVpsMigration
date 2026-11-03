terraform {
  required_version = ">= 1.10"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.106"
    }
  }

  # No backend block yet: state is local while testing. Moving it to a Space
  # means adding an S3 backend and running `terraform init -migrate-state`.
}

# Credentials come from the environment, never from variables or files:
#   DIGITALOCEAN_TOKEN                          API token (read and write)
#   SPACES_ACCESS_KEY_ID, SPACES_SECRET_ACCESS_KEY   Spaces keys
provider "digitalocean" {}
