# ============================================
# 14-router.tf
# Routers, Interfaces, and Peers
# ============================================

# Cloud Routers per project
# --------------------------------------------------------------
# Routers
# --------------------------------------------------------------
resource "google_compute_router" "routers" {
  for_each = local.tunnel_projects

  name    = "${each.value}-router"
  project = each.value
  region  = var.spoke_regions[each.value]
  network = local.vpc_ids[each.value]

  bgp {
    asn = (
      each.value == var.balerica_project ? 65501 :
      each.value == var.genosha_project  ? 65515 :
      65000 # fallback ASN for future spokes
    )
  }
}


# --------------------------------------------------------------
# Router interfaces (bind tunnels to routers with /30 ranges)
# --------------------------------------------------------------
resource "google_compute_router_interface" "interfaces" {
  for_each = {
    # Only process tunnels that actually exist (the working ones)
    for key, value in local.router_map :
    key => value if contains(keys(google_compute_vpn_tunnel.all), key)
  }

  name       = each.value.tunnel
  project    = each.value.src
  region     = each.value.region
  router     = google_compute_router.routers[each.value.src].name

  ip_range   = each.value.ip_range
  vpn_tunnel = google_compute_vpn_tunnel.all[each.key].name  # Now this works!
}

# --------------------------------------------------------------
# Router peers (BGP sessions across tunnels)
# --------------------------------------------------------------
resource "google_compute_router_peer" "peers" {
  for_each = {
    # Only process tunnels that actually exist (the working ones)
    for key, value in local.router_map :
    key => value if contains(keys(google_compute_vpn_tunnel.all), key)
  }

  name     = "${each.value.src}-to-${each.value.dst}-${each.value.name}-peer"
  project  = each.value.src
  region   = each.value.region
  router   = google_compute_router.routers[each.value.src].name

  interface     = google_compute_router_interface.interfaces[each.key].name

  # Use the correct peer IP from the tunnel definition
  peer_ip_address = split("/", local.vpn_tunnels_map[each.key].ip_dst)[0]
  peer_asn       = each.value.peer_asn
}

