# GCP Network Infrastructure
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network


/*******************************************************************************************************
# ===============================================
# GCP HA VPN Gateway - Balerica Singapore
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ha_vpn_gateway

# Dependency Chain: IAM → Gateways → Tunnels → Interfaces → Peers

# ===============================================
*******************************************************************************************************/

# HA VPN Gateway (Balerica side)
# ================================================
resource "google_compute_ha_vpn_gateway" "balerica_ha_vpn_gw" {
  provider = google.balerica
  name     = "balerica-ha-vpn-gw"
  project  = var.balerica_project
  region   = var.balerica_region
  network  = google_compute_network.balerica_vpc.id

  depends_on = [google_project_iam_member.allow_genosha_on_balerica]
}


# -----------------------------
# VPN Tunnels
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_vpn_tunnel
# -----------------------------

#===============================================
# Tunnel 0: Singapore (Balerica) → São Paulo (Genosha)
#===============================================

resource "google_compute_vpn_tunnel" "balerica_to_genosha_tunnel0" {
  provider                = google.balerica
  name                    = "balerica-to-genosha-tunnel0"
  project                 = var.balerica_project
  region                  = var.balerica_region
  vpn_gateway             = google_compute_ha_vpn_gateway.balerica_ha_vpn_gw.id
  vpn_gateway_interface   = 0
  peer_gcp_gateway        = google_compute_ha_vpn_gateway.genosha_ha_vpn_gw.id
  shared_secret           = var.tunnel0_psk
  router                  = google_compute_router.balerica_router.name
  ike_version             = 2  

  depends_on = [
    google_project_iam_member.allow_genosha_on_balerica,
    google_project_iam_member.allow_balerica_on_genosha,
    google_compute_ha_vpn_gateway.balerica_ha_vpn_gw,
    google_compute_ha_vpn_gateway.genosha_ha_vpn_gw
  ]
}


# =========================================================================================
# Router Interface (google_compute_router_interface") for tunnel0 here - see 14-router.tf
# balerica_router_interface_tunnel0
# name = "balerica-router-interface-tunnel0"
# =========================================================================================

# =========================================================================================
# Peer for Tunnel 0 - see 14-router.tf
# balerica_peer_tunnel0 
# name = "balerica-peer-tunnel0"
# =========================================================================================



resource "google_compute_vpn_tunnel" "balerica_to_genosha_tunnel1" {
  provider                = google.balerica
  name                    = "balerica-to-genosha-tunnel1"
  project                 = var.balerica_project
  region                  = var.balerica_region
  vpn_gateway             = google_compute_ha_vpn_gateway.balerica_ha_vpn_gw.id
  vpn_gateway_interface   = 1
  peer_gcp_gateway        = google_compute_ha_vpn_gateway.genosha_ha_vpn_gw.id
  shared_secret           = var.tunnel1_psk
  router                  = google_compute_router.balerica_router.name
  ike_version             = 2  

  depends_on = [
    google_project_iam_member.allow_genosha_on_balerica,
    google_project_iam_member.allow_balerica_on_genosha,
    google_compute_ha_vpn_gateway.balerica_ha_vpn_gw,
    google_compute_ha_vpn_gateway.genosha_ha_vpn_gw
  ]  
}

# =========================================================================================
# Router Interface (google_compute_router_interface") for tunnel1 here - see 14-router.tf
# balerica_router_interface_tunnel1
# name = "balerica-router-interface-tunnel1"
# =========================================================================================

# =========================================================================================
# Peer for Tunnel 1 - see 14-router.tf 
# balerica_peer_tunnel1
# name = "balerica-peer-tunnel1"
# =========================================================================================

