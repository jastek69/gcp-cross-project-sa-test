# ================================
# IAM Sanity Checks
# ================================

output "spoke_sas" {
  description = "Project → Terraform SA email"
  value       = local.spoke_sas
}

output "baseline_roles_applied" {
  description = "Baseline IAM role bindings per project"
  value = {
    for k, v in google_project_iam_member.baseline_roles : k => {
      project = v.project
      role    = v.role
      member  = v.member
    }
  }
}

output "cross_project_bindings" {
  description = "Cross-project VPN role bindings (src SA → dst project)"
  value = {
    for k, v in google_project_iam_member.cross_bindings : k => {
      src_project = v.member
      dst_project = v.project
      role        = v.role
    }
  }
}

# ================================
# VPN + Router Sanity Checks
# ================================

output "vpn_tunnels" {
  description = "All VPN tunnels created (flattened)"
  value = {
    for k, v in google_compute_vpn_tunnel.all : k => {
      name   = v.name
      src    = v.project
      region = v.region
      peer   = v.peer_ip
    }
  }
}

output "router_interfaces" {
  description = "Router interfaces created (flattened)"
  value = {
    for k, v in google_compute_router_interface.interfaces : k => {
      name   = v.name
      router = v.router
      region = v.region
      ip     = v.ip_range
    }
  }
}

output "router_peers" {
  description = "Router peers created (flattened)"
  value = {
    for k, v in google_compute_router_peer.peers : k => {
      name   = v.name
      router = v.router
      peer   = v.peer_ip_address
      asn    = v.peer_asn
    }
  }
}
