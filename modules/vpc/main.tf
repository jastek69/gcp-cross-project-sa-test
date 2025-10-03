############################################
# modules/vpc/main.tf
############################################

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.36.0"
    }
  }
}


variable "project" {
  type        = string
  description = "Project ID where the VPC will be created"
}

variable "name" {
  type        = string
  description = "VPC network name"
}

resource "google_compute_network" "this" {
  project                  = var.project
  name                     = var.name
  auto_create_subnetworks  = false
  mtu                      = 1460
  delete_default_routes_on_create = false
}

# ----------------------
# Outputs
# ----------------------

output "vpc_id" {
  description = "The self_link of the VPC network"
  value       = google_compute_network.this.id
}

output "vpc_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.this.name
}

output "vpc_self_link" {
  description = "The self_link of the VPC network (alias to vpc_id)"
  value       = google_compute_network.this.self_link
}
