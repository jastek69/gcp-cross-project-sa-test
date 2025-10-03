############################################################
# 05-vpn-tunnels.tf
# HA VPN Gateways + Tunnels
############################################################

# HA VPN Gateways (one per source project)
resource "google_compute_ha_vpn_gateway" "gateways" {
  for_each = local.tunnel_projects
  name    = "${each.value}-gateway" # remove "\" Escaping from name to fix error   
  project = each.value
  region  = var.spoke_regions[each.value]
  network = local.vpc_ids[each.value]
}


# --------------------------------------------------------------
# HA VPN Tunnels
# --------------------------------------------------------------
# Create only the tunnels that work (t0 and t1 from each direction)
resource "google_compute_vpn_tunnel" "all" {
  for_each = {
    # Only include working tunnel pairs
    "balerica-genosha-t0" = local.vpn_tunnels_map["balerica-genosha-t0"]
    "balerica-genosha-t1" = local.vpn_tunnels_map["balerica-genosha-t1"]
    "genosha-balerica-t0" = local.vpn_tunnels_map["genosha-balerica-t0"]
    "genosha-balerica-t1" = local.vpn_tunnels_map["genosha-balerica-t1"]

     # Future expansions - add new ones as needed:
    # "balerica-future-t0" = local.vpn_tunnels_map["balerica-future-t0"]  # Will work!
    # "future-balerica-t0" = local.vpn_tunnels_map["future-balerica-t0"]  # Will work!

  }

  name       = "${each.value.src}-to-${each.value.dst}-${each.value.name}"
  project    = each.value.src
  region     = each.value.region_src
  vpn_gateway = google_compute_ha_vpn_gateway.gateways[each.value.src].self_link

  # Select HA VPN interface index based on tunnel name (t0/t1/t2/t3 → 0/1)
  vpn_gateway_interface = local.interface_index[each.value.name]

  # Shared secret (PSK) from your tunnels map
  shared_secret = each.value.psk

  # Peer GCP Gateway - This is the key missing piece
  peer_gcp_gateway = google_compute_ha_vpn_gateway.gateways[each.value.dst].self_link

  # Use correct router reference
  router = google_compute_router.routers[each.value.src].self_link
  
  ike_version = 2
}
