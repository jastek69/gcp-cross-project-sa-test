
# https://registry.terraform.io/providers/hashicorp/google/latest/docs
# https://cloud.google.com/docs/authentication/getting-started


# -------------------------------
# Default Provider
# Needs a default provider to avoid errors
# -------------------------------

# Balerica set a default provider - no alias
provider "google" {
  project     = var.balerica_project
  region      = var.region1
  credentials = file("taaops-e9943412868a.json")
}



# -------------------------------
# Create Alias Providers for Multiple GCP Projects
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/multiple-project


# -------------------------------
# Provider for taaops (balerica) - Alias for Balerica
# -------------------------------
provider "google" {
  alias       = "balerica"
  project     = var.balerica_project
  region      = var.balerica_region
  credentials = file(var.balerica_credentials_file)
}



# -------------------------------
# Provider for genosha-ops
# Alias for Genosha
# -------------------------------
provider "google" {
  alias       = "genosha-ops"
  project     = var.genosha_project
  region      = var.genosha_region
  credentials = file(var.genosha_credentials_file)
}



/*
# -------------------------------
# Example how to use with alias
# -------------------------------

# A resource in taaops (balerica)
resource "google_compute_network" "balerica_network" {
  provider = google.balerica
  name     = "balerica-vpc"
  auto_create_subnetworks = false
}

# A resource in genosha-ops
resource "google_compute_network" "genosha_network" {
  provider = google.genosha-ops
  name     = "genosha-vpc"
  auto_create_subnetworks = false
}
*/


/* Moved to providers.tf
terraform {
  backend "gcs" {
    bucket      = "taaopsfirstterraformbucket"
    prefix      = "terraform/state091225b"
    credentials = "taaops-e9943412868a.json"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.36.0"
    }
  }
}
*/

