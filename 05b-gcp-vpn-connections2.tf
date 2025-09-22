# GCP HA VPN Gateway SAO PAULO
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ha_vpn_gateway

# ================================================
# HA VPN Gateway (Genosha side)
# ================================================
resource "google_compute_ha_vpn_gateway" "genosha_ha_vpn_gw" {
  provider = google.genosha-ops
  name     = "genosha-ha-vpn-gw"
  project  = var.genosha_project
  region  = var.genosha_region
  network = google_compute_network.genosha_vpc.id

  # Gateway depends on IAM roles + bindings being created
  depends_on = [google_project_iam_member.allow_balerica_on_genosha]
}


# ======================================================
# Genosha → Balerica VPN Tunnels
# ======================================================
resource "google_compute_vpn_tunnel" "genosha_to_balerica_tunnel0" {
  provider                = google.genosha-ops
  name                    = "genosha-to-balerica-tunnel0"
  project                 = var.genosha_project
  region                  = var.genosha_region
  vpn_gateway             = google_compute_ha_vpn_gateway.genosha_ha_vpn_gw.id
  vpn_gateway_interface   = 0
  peer_gcp_gateway        = google_compute_ha_vpn_gateway.balerica_ha_vpn_gw.id
  shared_secret           = var.tunnel0_psk
  router                  = google_compute_router.genosha_router.name
  ike_version             = 2

  depends_on = [
    google_project_iam_member.allow_balerica_on_genosha,
    google_project_iam_member.allow_genosha_on_balerica,
    google_compute_ha_vpn_gateway.genosha_ha_vpn_gw,
    google_compute_ha_vpn_gateway.balerica_ha_vpn_gw
  ]
}



# =========================================================================================
# Router Interface (google_compute_router_interface") for tunnel0 here - see 14-router.tf
# genosha_router_interface_tunnel0
# name = "genosha-router-interface-tunnel0"
# =========================================================================================

# =========================================================================================
# Peer for tunnel0 - see 14-router.tf
# balerica_peer_tunnel0 
# name = "genosha-peer-tunnel0"
# =========================================================================================




resource "google_compute_vpn_tunnel" "genosha_to_balerica_tunnel1" {
  provider                = google.genosha-ops
  name                    = "genosha-to-balerica-tunnel1"
  project                 = var.genosha_project
  region                  = var.genosha_region
  vpn_gateway             = google_compute_ha_vpn_gateway.genosha_ha_vpn_gw.id
  vpn_gateway_interface   = 1
  peer_gcp_gateway        = google_compute_ha_vpn_gateway.balerica_ha_vpn_gw.id
  shared_secret           = var.tunnel1_psk
  router                  = google_compute_router.genosha_router.name
  ike_version             = 2
  
  depends_on = [
    google_project_iam_member.allow_balerica_on_genosha,
    google_project_iam_member.allow_genosha_on_balerica,
    google_compute_ha_vpn_gateway.genosha_ha_vpn_gw,
    google_compute_ha_vpn_gateway.balerica_ha_vpn_gw
  ]
}

# =========================================================================================
# Router Interface (google_compute_router_interface") for tunnel1 here - see 14-router.tf
# genosha_router_interface_tunnel1
# name = "genosha-router-interface-tunnel1"
# =========================================================================================

# =========================================================================================
# Peer for tunnel1 - see 14-router.tf
# genosha_peer_tunnel1
# name = "genosha-peer-tunnel1"
# =========================================================================================
