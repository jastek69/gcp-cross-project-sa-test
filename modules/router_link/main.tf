############################################
# modules/router_link/main.tf
# Creates Router Interface + Router Peer
############################################

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.36.0"
    }
  }
}


variable "project"   { type = string }
variable "region"    { type = string }
variable "router"    { type = string }
variable "ip_range"  { type = string }
variable "tunnel"    { type = string }
variable "peer_ip"   { type = string }
variable "peer_asn"  { type = number }
variable "name"      { type = string }

resource "google_compute_router_interface" "this" {
  name       = "${var.name}-if"
  project    = var.project
  region     = var.region
  router     = var.router
  ip_range   = var.ip_range
  vpn_tunnel = var.tunnel
}

resource "google_compute_router_peer" "this" {
  name                      = "${var.name}-peer"
  project                   = var.project
  region                    = var.region
  router                    = var.router
  interface                 = google_compute_router_interface.this.name
  peer_ip_address           = var.peer_ip
  peer_asn                  = var.peer_asn
  advertised_route_priority = 100
}

output "interface_name" {
  value = google_compute_router_interface.this.name
}
############################################
# modules/router_link/main.tf
# Bundle Router Interface + Router Peer
############################################

variable "project" {
  type        = string
  description = "Project ID where the router interface/peer is created"
}

variable "region" {
  type        = string
  description = "Region for the router interface/peer"
}

variable "router" {
  type        = string
  description = "Name of the router to attach interface to"
}

variable "ip_range" {
  type        = string
  description = "CIDR IP range for the router interface"
}

variable "tunnel" {
  type        = string
  description = "VPN tunnel name for this interface"
}

variable "peer_ip" {
  type        = string
  description = "Peer router IP address (without subnet mask)"
}

variable "peer_asn" {
  type        = number
  description = "Peer ASN for BGP"
}

variable "name" {
  type        = string
  description = "Name suffix for router interface + peer"
}

# Router Interface
resource "google_compute_router_interface" "this" {
  project = var.project
  region  = var.region
  name    = "${var.router}-${var.name}-if"
  router  = var.router
  ip_range   = var.ip_range
  vpn_tunnel = var.tunnel
}

# Router Peer
resource "google_compute_router_peer" "this" {
  project   = var.project
  region    = var.region
  name      = "${var.router}-${var.name}-peer"
  router    = var.router
  peer_ip_address = var.peer_ip
  peer_asn        = var.peer_asn
  interface       = google_compute_router_interface.this.name
}

# -----------------------
# Outputs
# -----------------------
output "interface_name" {
  value       = google_compute_router_interface.this.name
  description = "Router interface name"
}

output "peer_name" {
  value       = google_compute_router_peer.this.name
  description = "Router peer name"
}
