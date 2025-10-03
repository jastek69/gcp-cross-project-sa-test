# Create custom VPN role in both projects
resource "google_project_iam_custom_role" "vpn_role_taaops" {
  project = "taaops"
  role_id = "vpn_role"
  title   = "VPN Role"
  permissions = [
    "compute.instances.get",
    "compute.networks.get",
    "compute.networks.list",
    "compute.subnetworks.get",
    "compute.subnetworks.list",
    "compute.vpnTunnels.create",
    "compute.vpnTunnels.delete",
    "compute.vpnTunnels.get",
    "compute.vpnTunnels.list",
    "compute.vpnGateways.create",
    "compute.vpnGateways.delete",
    "compute.vpnGateways.get",
    "compute.vpnGateways.list",
    "compute.routers.create",
    "compute.routers.delete",
    "compute.routers.get",
    "compute.routers.list",
    "compute.routers.update",
  ]
}

resource "google_project_iam_custom_role" "vpn_role_genosha" {
  project = "genosha-ops"
  role_id = "vpn_role"
  title   = "VPN Role"
  permissions = [
    "compute.instances.get",
    "compute.networks.get",
    "compute.networks.list",
    "compute.subnetworks.get",
    "compute.subnetworks.list",
    "compute.vpnTunnels.create",
    "compute.vpnTunnels.delete",
    "compute.vpnTunnels.get",
    "compute.vpnTunnels.list",
    "compute.vpnGateways.create",
    "compute.vpnGateways.delete",
    "compute.vpnGateways.get",
    "compute.vpnGateways.list",
    "compute.routers.create",
    "compute.routers.delete",
    "compute.routers.get",
    "compute.routers.list",
    "compute.routers.update",
  ]
}
