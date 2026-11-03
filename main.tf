locals {
  name        = "${var.project}-${var.environment}"
  deploy_user = "deploy"

  project_environment = var.environment == "prod" ? "Production" : "Development"
}

module "network" {
  source = "./modules/network"

  name     = local.name
  region   = var.region
  vpc_cidr = var.vpc_cidr
}

module "compute" {
  source = "./modules/compute"

  name                 = local.name
  region               = var.region
  size                 = var.droplet_size
  image                = var.droplet_image
  vpc_id               = module.network.vpc_id
  tags                 = [module.network.droplet_tag]
  admin_ssh_public_key = var.admin_ssh_public_key

  # cloud-init lives at the repo root so the rest of the kit stays
  # provider-agnostic; this module only passes it to the Droplet.
  user_data = templatefile("${path.root}/cloud-init/cloud-config.yaml.tftpl", {
    deploy_user            = local.deploy_user
    deploy_ssh_public_keys = var.deploy_ssh_public_keys
  })
}

module "storage" {
  source = "./modules/storage"

  create         = var.create_backup_bucket
  name           = var.backup_bucket_name
  region         = var.region
  retention_days = var.backup_retention_days
  force_destroy  = var.backup_bucket_force_destroy
}

module "project" {
  source = "./modules/project"

  name        = local.name
  environment = local.project_environment
  resource_urns = compact([
    module.compute.droplet_urn,
    module.compute.reserved_ip_urn,
    module.storage.bucket_urn,
  ])
}
