############################################
# modules/subnet/main.tf
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
  description = "Project ID for the subnet"
}

variable "region" {
  type        = string
  description = "Region where the subnet will be created"
}

variable "cidr" {
  type        = string
  description = "CIDR range for the subnet"
}

variable "network" {
  type        = string
  description = "Parent VPC network self_link or name"
}

variable "name" {
  type        = string
  description = "Subnet name"
}

resource "google_compute_subnetwork" "this" {
  project                  = var.project
  name                     = var.name
  ip_cidr_range            = var.cidr
  region                   = var.region
  network                  = var.network
  private_ip_google_access = true
}

# ----------------------
# Outputs
# ----------------------

output "subnet_id" {
  description = "The ID/self_link of the subnet"
  value       = google_compute_subnetwork.this.id
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = google_compute_subnetwork.this.name
}

output "subnet_self_link" {
  description = "The self_link of the subnet"
  value       = google_compute_subnetwork.this.self_link
}
