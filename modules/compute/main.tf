# Compute Module
# modules/compute/main.tf

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
  description = "Project ID"
}

variable "zone" {
  type        = string
  description = "Zone for the VM"
}

variable "instance_name" {
  type        = string
  description = "Name of the VM instance"
}

variable "machine_type" {
  type        = string
  description = "Machine type (e.g., n2-standard-2)"
}

variable "subnetwork" {
  type        = string
  description = "Subnetwork ID"
}

variable "startup_scripts" {
  type        = map(string)
  description = "Map of project → startup script path"
}

variable "service_account_email" {
  type        = string
  description = "Service account email for the VM"
}

resource "google_compute_instance" "vm" {
  name         = var.instance_name
  project      = var.project
  zone         = var.zone
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = var.subnetwork
  }

  metadata_startup_script = file("${path.root}/${var.startup_scripts[var.project]}")

  service_account {
    email  = var.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

# Outputs
output "instance_name" {
  value = google_compute_instance.vm.name
}

output "instance_self_link" {
  value = google_compute_instance.vm.self_link
}
