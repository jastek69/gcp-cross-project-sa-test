resource "google_network_connectivity_hub" "balerica-hub" {
  provider    = google.balerica
  project     = var.project_id1
  name        = "balerica-hub"
  description = "Central hub for balerica connectivity"
}


resource "google_network_connectivity_hub" "genosha-hub" {
  provider    = google.genosha-ops
  project     = var.project_id2
  name        = "genosha-hub"
  description = "Central hub for genosha connectivity"
}
