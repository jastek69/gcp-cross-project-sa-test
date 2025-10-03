############################################
# modules/spoke/main.tf
############################################

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.36.0"
    }
  }
}


variable "project"        { type = string }
variable "region"         { type = string }
variable "hub_id"         { type = string }
variable "vpn_tunnel_uris" { type = list(string) }
variable "name"           { type = string }

resource "google_network_connectivity_spoke" "this" {
  name     = "${var.name}-spoke"
  location = var.region
  hub      = var.hub_id

  linked_vpn_tunnels {
    uris                   = var.vpn_tunnel_uris
    site_to_site_data_transfer = true
  }

  description = "VPN Spoke for ${var.name}"
}

output "spoke_id" {
  value = google_network_connectivity_spoke.this.id
}
