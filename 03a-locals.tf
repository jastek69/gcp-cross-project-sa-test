# ============================================================
# 03a-locals.tf
# Locals for IAM, VPN Tunnels, and Router Interfaces
# ============================================================

  # ------------------------------------------------------------
  # Canonical map of project → Terraform SA email
  # ------------------------------------------------------------
 
 # ============================================
# 03a-locals.tf
# Central locals for VPCs, IAM, VPNs, Routers
# ============================================

locals {
  # -------------------------------------------------------------------
  # Canonical map of project → Terraform SA email
  # -------------------------------------------------------------------
  spoke_sas = merge(
    var.spokes,
    {
      (var.balerica_project) = var.balerica_sa
      (var.genosha_project)  = var.genosha_sa
    }
  )

  # -------------------------------------------------------------------
  # Baseline roles → expand into bindings
  # -------------------------------------------------------------------
  baseline_roles = toset([
    "roles/viewer",
    "roles/compute.networkAdmin",
    "roles/networkconnectivity.admin",
  ])

  baseline_bindings = flatten([
    for project, sa in local.spoke_sas : [
      for role in local.baseline_roles : {
        key     = "${project}-${role}"
        project = project
        sa      = sa
        role    = role
      }
    ]
  ])

  baseline_bindings_map = {
    for b in local.baseline_bindings : b.key => b
  }

  # -------------------------------------------------------------------
  # Cross-project impersonation (vpn_role sharing)
  # -------------------------------------------------------------------
  cross_bindings = flatten([
    for src, sa in local.spoke_sas : [
      for dst, _ in local.spoke_sas : {
        key = "${src}->${dst}"
        src = src
        dst = dst
        sa  = sa
      }
      if src != dst
    ]
  ])

  cross_bindings_map = {
    for b in local.cross_bindings : b.key => b
  }

  # -------------------------------------------------------------------
  # VPC IDs keyed by project (from VPC modules)
  # -------------------------------------------------------------------
  vpc_ids = {
    taaops      = module.balerica_vpc.vpc_id
    genosha-ops = module.genosha_vpc.vpc_id
    # future spokes extend here
  }

  # -------------------------------------------------------------------
  # Flattened VPN tunnels (from var.tunnels HA definition)
  # -------------------------------------------------------------------
  vpn_tunnels_flattened = flatten([
    for k, v in var.tunnels : [
      for tname, t in v.tunnels : {
        tunnel_key  = "${k}-${tname}"   # e.g., balerica-genosha-t0
        name        = tname
        src         = v.src
        dst         = v.dst
        region_src  = v.region_src
        region_dst  = v.region_dst
        psk         = t.psk
        ip_src      = t.ip_src
        ip_dst      = t.ip_dst
        asn_src     = v.asn_src
        asn_dst     = v.asn_dst
      }
    ]
  ])

  vpn_tunnels_map = {
    for tunnel in local.vpn_tunnels_flattened :
    tunnel.tunnel_key => tunnel
  }

  # -------------------------------------------------------------------
  # Tunnel participants (all unique projects)
  # -------------------------------------------------------------------
  tunnel_projects = toset(flatten([for _, v in var.tunnels : [v.src, v.dst]]))

  # Map tunnel label ("t0"/"t1") to HA gateway interface index
  interface_index = {
    t0 = 0
    t1 = 1
    t2 = 0
    t3 = 1
  # predefine more if you will scale further
}

  # -------------------------------------------------------------------
  # Flattened router interfaces (bind tunnels to routers)
  # -------------------------------------------------------------------
  router_flattened = flatten([
    for k, v in var.tunnels : [
      for tname, t in v.tunnels : {
        router_key = "${k}-${tname}"
        src        = v.src
        dst        = v.dst
        region     = v.region_src
        router     = "${v.src}-router"
        ip_range   = t.ip_src      # your 169.254.x.x/30 goes here
        tunnel     = "${v.src}-to-${v.dst}-${tname}"
        peer_asn   = v.asn_dst
        name       = tname
      }
    ]
  ])

  router_map = {
    for r in local.router_flattened : r.router_key => r
  }
}

