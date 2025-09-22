# ======================================================
# Router for Balerica
# ======================================================
resource "google_compute_router" "balerica_router" {
  provider = google.balerica
  name     = "balerica-router"
  region   = var.balerica_region
  network  = google_compute_network.balerica_vpc.id

  bgp {
    asn              = var.balerica_bgp_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }

  depends_on = [
    google_project_iam_member.allow_genosha_on_balerica
  ]
}

# Router Interface for Tunnel 0
resource "google_compute_router_interface" "balerica_router_interface_tunnel0" {
  provider   = google.balerica
  project    = var.balerica_project
  name       = "balerica-router-interface-tunnel0"
  router     = google_compute_router.balerica_router.name
  region     = var.balerica_region
  ip_range   = var.balerica_router_ip_tunnel0
  vpn_tunnel = google_compute_vpn_tunnel.balerica_to_genosha_tunnel0.name

  depends_on = [google_compute_vpn_tunnel.balerica_to_genosha_tunnel0]
}

resource "google_compute_router_peer" "balerica_peer_tunnel0" {
  provider                  = google.balerica
  project                   = var.balerica_project
  name                      = "balerica-peer-tunnel0"
  router                    = google_compute_router.balerica_router.name
  region                    = var.balerica_region
  peer_ip_address           = split("/", var.genosha_router_ip_tunnel0)[0] # Peer IP only
  peer_asn                  = var.genosha_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.balerica_router_interface_tunnel0.name

  depends_on = [google_compute_router_interface.balerica_router_interface_tunnel0]
}

# Router Interface for Tunnel 1
resource "google_compute_router_interface" "balerica_router_interface_tunnel1" {
  provider   = google.balerica
  project    = var.balerica_project
  name       = "balerica-router-interface-tunnel1"
  router     = google_compute_router.balerica_router.name
  region     = var.balerica_region
  ip_range   = var.balerica_router_ip_tunnel1
  vpn_tunnel = google_compute_vpn_tunnel.balerica_to_genosha_tunnel1.name

  depends_on = [google_compute_vpn_tunnel.balerica_to_genosha_tunnel1]
}

resource "google_compute_router_peer" "balerica_peer_tunnel1" {
  provider                  = google.balerica
  project                   = var.balerica_project
  name                      = "balerica-peer-tunnel1"
  router                    = google_compute_router.balerica_router.name
  region                    = var.balerica_region
  peer_ip_address           = split("/", var.genosha_router_ip_tunnel1)[0]
  peer_asn                  = var.genosha_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.balerica_router_interface_tunnel1.name

  depends_on = [google_compute_router_interface.balerica_router_interface_tunnel1]
}


# ======================================================
# Router for Genosha
# ======================================================
resource "google_compute_router" "genosha_router" {
  provider = google.genosha-ops
  name     = "genosha-router"
  region   = var.genosha_region
  network  = google_compute_network.genosha_vpc.id

  bgp {
    asn              = var.genosha_bgp_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }

  depends_on = [
    google_project_iam_member.allow_balerica_on_genosha
  ]
}

# Router Interface for Tunnel 0
resource "google_compute_router_interface" "genosha_router_interface_tunnel0" {
  provider   = google.genosha-ops
  project    = var.genosha_project
  name       = "genosha-router-interface-tunnel0"
  router     = google_compute_router.genosha_router.name
  region     = var.genosha_region
  ip_range   = var.genosha_router_ip_tunnel0
  vpn_tunnel = google_compute_vpn_tunnel.genosha_to_balerica_tunnel0.name

  depends_on = [google_compute_vpn_tunnel.genosha_to_balerica_tunnel0]
}

resource "google_compute_router_peer" "genosha_peer_tunnel0" {
  provider                  = google.genosha-ops
  project                   = var.genosha_project
  name                      = "genosha-peer-tunnel0"
  router                    = google_compute_router.genosha_router.name
  region                    = var.genosha_region
  peer_ip_address           = split("/", var.balerica_router_ip_tunnel0)[0]
  peer_asn                  = var.balerica_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.genosha_router_interface_tunnel0.name

  depends_on = [google_compute_router_interface.genosha_router_interface_tunnel0]
}

# Router Interface for Tunnel 1
resource "google_compute_router_interface" "genosha_router_interface_tunnel1" {
  provider   = google.genosha-ops
  project    = var.genosha_project
  name       = "genosha-router-interface-tunnel1"
  router     = google_compute_router.genosha_router.name
  region     = var.genosha_region
  ip_range   = var.genosha_router_ip_tunnel1
  vpn_tunnel = google_compute_vpn_tunnel.genosha_to_balerica_tunnel1.name

  depends_on = [google_compute_vpn_tunnel.genosha_to_balerica_tunnel1]
}

resource "google_compute_router_peer" "genosha_peer_tunnel1" {
  provider                  = google.genosha-ops
  project                   = var.genosha_project
  name                      = "genosha-peer-tunnel1"
  router                    = google_compute_router.genosha_router.name
  region                    = var.genosha_region
  peer_ip_address           = split("/", var.balerica_router_ip_tunnel1)[0]
  peer_asn                  = var.balerica_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.genosha_router_interface_tunnel1.name

  depends_on = [google_compute_router_interface.genosha_router_interface_tunnel1]
}
