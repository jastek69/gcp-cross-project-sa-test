# Providers

terraform {
  backend "gcs" {
    bucket      = "taaopsfirstterraformbucket"
    prefix      = "terraform/state100125"
    credentials = "taaops-e9943412868a.json"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.36.0"
    }
  }
}

############################################
# 01-providers.tf
# Explicit provider aliases per project
############################################

# Default provider → use Balerica as the hub project
provider "google" {
  project                     = var.balerica_project
  region                      = var.balerica_region
  impersonate_service_account = var.bootstrap_mode ? null : var.balerica_sa
}


# Explicit provider for Balerica
provider "google" {
  alias                       = "taaops"
  project                     = var.balerica_project
  region                      = var.balerica_region
  impersonate_service_account = var.bootstrap_mode ? null : local.spoke_sas[var.balerica_project]
}

# Explicit provider for Genosha
provider "google" {
  alias                       = "genosha_ops"
  project                     = var.genosha_project
  region                      = var.genosha_region
  impersonate_service_account = var.bootstrap_mode ? null : local.spoke_sas[var.genosha_project]
}

# TODO: For new spokes, copy the pattern above and assign alias = "<project_id>"

# Future expansion: add Atlantis, Dale, Tiqs here as needed
# Example:
# provider "google" {
#   alias                       = "atlantis-ops"
#   project                     = "atlantis-ops"
#   region                      = var.atlantis_region
#   impersonate_service_account = var.bootstrap_mode ? null : local.spoke_sas["atlantis-ops"]
# }
