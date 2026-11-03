terraform {
  required_version = ">= 1.10"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.106"
    }
  }

  # No backend block yet: state is local while testing. To move it to a Space,
  # add `backend "s3" {}` here (settings live in backend.hcl, see
  # backend.hcl.example) and run
  # `terraform init -backend-config=backend.hcl -migrate-state`.
}

# Credentials come from the environment, never from variables or files:
#   DIGITALOCEAN_TOKEN                          API token (read and write)
#   SPACES_ACCESS_KEY_ID, SPACES_SECRET_ACCESS_KEY   Spaces keys
provider "digitalocean" {}
