# Balerica Hub
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/network_connectivity_hub

# -------------------------------------------------------------------
# Create a Network Connectivity Hub for each project
# Every project in your local.spoke_sas automatically gets its own hub (e.g. taaops-hub, genosha-ops-hub, later atlantis-ops-hub).
# -------------------------------------------------------------------
############################################################
# Network Connectivity Hubs
############################################################

module "balerica_hub" {
  source = "./modules/hub"

  providers = {
    google = google.taaops
  }

  project = var.balerica_project
  name    = "balerica"
}

module "genosha_hub" {
  source = "./modules/hub"

  providers = {
    google = google.genosha_ops
  }

  project = var.genosha_project
  name    = "genosha"
}
