# ===================================================================================
# Balerica VPN Spoke inside taaops and connects to Balerica Hub via HA VPN Gateway
# ===================================================================================
resource "google_network_connectivity_spoke" "vpn-spoke-balerica" {
  provider = google.balerica
  name     = "vpn-spoke-balerica"
  location = var.region1
  # location = "global" # Spoke location is global for VPC spokes
  hub = google_network_connectivity_hub.balerica-hub.id
  linked_vpn_tunnels {
    uris = [
      google_compute_vpn_tunnel.balerica_to_genosha_tunnel0.self_link,
      google_compute_vpn_tunnel.balerica_to_genosha_tunnel1.self_link,
    ]
    site_to_site_data_transfer = true
  }
  description = "Balerica VPN Spoke for HA VPN Connection"
}


# ===================================================================================
# Balerica VPC Spokes - genosha-ops
# ===================================================================================

resource "google_network_connectivity_spoke" "vpn-spoke-genosha" {
  provider = google.genosha-ops
  name     = "vpn-spoke-genosha"
  location = var.region2
  # location = "global" # Spoke location is global for VPC spokes
  hub = google_network_connectivity_hub.balerica-hub.id
  linked_vpn_tunnels {
    site_to_site_data_transfer = true
    uris                       = [google_compute_vpn_tunnel.genosha_to_balerica_tunnel0.id]
  }
  description = "Genosha VPC Spoke in Balerica"
}


/*
# ===================================================================================
# Genhosha VPC Spoke to Hub - genosha-ops
# ===================================================================================


resource "google_network_connectivity_spoke" "vpn-tiqs-spoke-sao" {
  provider = google.genosha-ops
  name     = "vpn-tiqs-spoke-sao"
  location = var.region2
  # location = "global" # Spoke location is global for VPC spokes
  hub = google_network_connectivity_hub.balerica-hub.id
  linked_vpn_tunnels {
    site_to_site_data_transfer = true
    uris                       = [google_compute_vpn_tunnel.genosha-tunnel0.id]
  }
  description = "TAA VPC Spoke in Balerica"
}
*/

