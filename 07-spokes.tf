############################################################
# VPN Spokes
############################################################

module "balerica_spoke" {
  source = "./modules/spoke"

  providers = {
    google = google.taaops
  }

  project         = var.balerica_project
  region          = var.balerica_region
  name            = "balerica"
  hub_id          = module.balerica_hub.hub_id
  vpn_tunnel_uris = [
    google_compute_vpn_tunnel.all["balerica-genosha-t0"].self_link,
    google_compute_vpn_tunnel.all["balerica-genosha-t1"].self_link,
  ]
}

module "genosha_spoke" {
  source = "./modules/spoke"

  providers = {
    google = google.genosha_ops
  }

  project         = var.genosha_project
  region          = var.genosha_region
  name            = "genosha"
  hub_id          = module.genosha_hub.hub_id
  vpn_tunnel_uris = [
    google_compute_vpn_tunnel.all["genosha-balerica-t0"].self_link,
    google_compute_vpn_tunnel.all["genosha-balerica-t1"].self_link,
  ]
}
