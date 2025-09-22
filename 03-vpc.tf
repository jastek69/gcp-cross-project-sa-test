
# GCP Network Infrastructure 
# Terraform resource names → use underscores (balerica_vpc)
# GCP name field values → must use hyphens (balerica-vpc)

resource "google_compute_network" "balerica_vpc" {
  provider = google.balerica
  name     = "balerica-vpc"  #GCP network names use hyphens not underscores
  # routing_mode                    = "GLOBAL"
  auto_create_subnetworks         = false
  mtu                             = 1460
  delete_default_routes_on_create = false
}



resource "google_compute_network" "genosha_vpc" {
  provider = google.genosha-ops
  name     = "genosha-vpc"
  # routing_mode                    = "GLOBAL"
  auto_create_subnetworks         = false
  mtu                             = 1460
  delete_default_routes_on_create = false
}


/*
resource "google_compute_network" "taa-vpc" {
  provider = google.balerica
  name     = "taa-vpc"
  # routing_mode                    = "GLOBAL"
  auto_create_subnetworks         = false
  mtu                             = 1460
  delete_default_routes_on_create = false
}


resource "google_compute_network" "tiqs-vpc" {
  provider = google.genosha-ops
  name     = "tiqs-vpc"
  # routing_mode                      = "GLOBAL"
  mtu                             = 1460
  auto_create_subnetworks         = false
  delete_default_routes_on_create = false
}


resource "google_compute_network" "tokyo-vpc" {
  provider = google.balerica
  name     = "tokyo-vpc"
  # routing_mode                    = "GLOBAL"
  mtu                             = 1460
  auto_create_subnetworks         = false
  delete_default_routes_on_create = false
}
*/