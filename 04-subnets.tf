
# GCP Network Infrastructure 
resource "google_compute_subnetwork" "balerica_subnet" {
  provider                 = google.balerica
  name                     = "balerica-subnet"
  ip_cidr_range            = "10.25.0.0/24"
  region                   = var.region1
  network                  = google_compute_network.balerica_vpc.id
  private_ip_google_access = true
}





resource "google_compute_subnetwork" "genosha_subnet" {
  provider                 = google.genosha-ops
  name                     = "genosha-subnet"
  ip_cidr_range            = "10.20.0.0/24"
  region                   = var.region2
  network                  = google_compute_network.genosha_vpc.id
  private_ip_google_access = true
}





/*
resource "google_compute_subnetwork" "taa-subnet" {
  provider                 = google.balerica
  name                     = "taa-subnet"
  ip_cidr_range            = "10.10.0.0/24"
  region                   = var.region1
  network                  = google_compute_network.taa-vpc.id
  private_ip_google_access = true
}




resource "google_compute_subnetwork" "tiqs-subnet" {
  provider                 = google.genosha-ops
  name                     = "tiqs-subnet"
  ip_cidr_range            = "10.55.80.0/24"
  region                   = var.region2
  network                  = google_compute_network.tiqs-vpc.id
  private_ip_google_access = true
}


# Taa VPC - Tokyo
resource "google_compute_subnetwork" "tokyo-subnet" {
  provider                 = google.balerica
  name                     = "tokyo-subnet"
  ip_cidr_range            = "10.65.80.0/24"
  region                   = var.region5
  network                  = google_compute_network.tokyo-vpc.id
  private_ip_google_access = true
}


*/

# ===================================================================================
# PROXY SUBNETS for VPC Peering
# ===================================================================================

/*
# Regional Proxy Only Subnet for LB
# Required for Regional Application Load Balancer for traffic offloading
resource "google_compute_subnetwork" "balerica_regional_proxy_subnet" {
  provider      = google.balerica
  name          = "balerica-regional-proxy-subnet"
  region        = var.region1
  ip_cidr_range = "198.168.255.0/24" # Example CIDR, adjust as needed - use non-common range for security and ease troubleshooting
  # This purpose reserves this subnet for regional Envoy-based load balancers
  purpose = "REGIONAL_MANAGED_PROXY"
  network = google_compute_network.balerica-vpc.id
  role    = "ACTIVE"
}


# Required for Regional Application Load Balancer for traffic offloading
resource "google_compute_subnetwork" "genosha_regional_proxy_subnet" {
  provider      = google.genosha-ops
  name          = "genosha-regional-proxy-subnet"
  region        = var.region2
  ip_cidr_range = "198.168.255.0/24" # Example CIDR, adjust as needed - use non-common range for security and ease troubleshooting
  # This purpose reserves this subnet for regional Envoy-based load balancers
  purpose = "REGIONAL_MANAGED_PROXY"
  network = google_compute_network.genosha-vpc.id
  role    = "ACTIVE"
}
*/
