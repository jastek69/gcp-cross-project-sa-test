# Hub Module

# modules/hub/main.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.36.0"
    }
  }
}


variable "project" { type = string }
variable "name"    { type = string }

resource "google_network_connectivity_hub" "this" {
  name        = "${var.name}-hub"
  project     = var.project
  description = "Central hub for ${var.name} connectivity"
}

output "hub_id" {
  value = google_network_connectivity_hub.this.id
}
