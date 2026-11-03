resource "digitalocean_project" "this" {
  name        = var.name
  description = "Tic-tac-toe app migrated from AWS."
  purpose     = "Web Application"
  environment = var.environment
}

resource "digitalocean_project_resources" "this" {
  project   = digitalocean_project.this.id
  resources = var.resource_urns
}
