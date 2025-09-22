
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam_custom_role
# IAM Role and Binding for VPN Gateway Usage

/**************************************************************************************
# =====================================================================================
# NOTES about this IAM configuration:
# Dependency chain: IAM → Gateways → Tunnels → Interfaces → Peers.
#
# This file manages IAM roles and bindings for cross-project VPN access.
# It creates custom roles with minimal permissions and binds them to service accounts.
#     * Look up project metadata dynamically
#     * Service accounts are created with short account_id = "terraform".
#     * .tfvars overrides (balerica_sa, genosha_sa) can be used if you want pre-existing SAs.
#     * Locals unify the references (local.balerica_sa_email, local.genosha_sa_email).
#     * Custom roles grant minimal VPN permissions.
#     * IAM bindings always reference the correct service account.
#     * depends_on enforces role creation before bindings.

account_id = "terraform" → creates SAs like:
      terraform@balerica-ops.iam.gserviceaccount.com
      terraform@genosha-ops.iam.gserviceaccount.com

.tfvars lets you override with:
      balerica_sa = "my-preexisting-sa@balerica-ops.iam.gserviceaccount.com"
      genosha_sa  = "another-sa@genosha-ops.iam.gserviceaccount.com"

So Terraform won’t try to create them; it will use those for IAM bindings.

      * locals unify this logic so all bindings reference the right SA.
      * Roles are minimal and custom
# ========================================================================================
******************************************************************************************/


# Project Data Sources for cross-project IAM bindings

# Balerica Project
data "google_project" "balerica" {
  provider   = google.balerica
  project_id = var.balerica_project
}


# Genosha Project
data "google_project" "genosha" {
  provider   = google.genosha-ops
  project_id = var.genosha_project
}


#==============================================================================
# Service Accounts - Terraform managed Service Accounts, with override option
# =============================================================================

# Create the service account FIRST

# Balerica Service Account
resource "google_service_account" "balerica_terraform_sa" {
  provider     = google.balerica
  #account_id   = "taaops-e9943412868a" # Must match credentials filename prefix
  account_id = "terraform" # results in terraform@balerica-ops.iam.gserviceaccount.com
  display_name = "Terraform Service Account for Balerica"
}


# Genosha Service Account
resource "google_service_account" "genosha_terraform_sa" {
  provider     = google.genosha-ops
  #account_id   = "genosha-ops-78a3599fb148" # Must match credentials filename prefix
  account_id = "terraform" # results in terraform@genosha-ops.iam.gserviceaccount.com
  display_name = "Terraform Service Account for Genosha"
}


#Local overrides - use tfvars if provided, otherwise use the created SA
locals {
  balerica_sa_email = var.balerica_sa != "" ? var.balerica_sa : google_service_account.balerica_terraform_sa.email
  genosha_sa_email  = var.genosha_sa  != "" ? var.genosha_sa  : google_service_account.genosha_terraform_sa.email
}


# ================================================
# Custom Roles
# Custom Role with minimal VPN permissions in each project
# Create Genosha custom IAM role
#===============================================

resource "google_project_iam_custom_role" "genosha_vpn_role" {
  provider    = google.genosha-ops
  project     = var.genosha_project # Explicitly
  role_id     = "customVpnAccess"
  title       = "Custom VPN Access Role"
  description = "Allows minimal permissions for VPN gateway usage"

  permissions = [
    "compute.vpnGateways.use",
    "compute.vpnTunnels.create",
    "compute.vpnTunnels.delete",
    "compute.vpnTunnels.get",
    "compute.vpnTunnels.list",
    "compute.routers.use",
    "compute.networks.use",
    "compute.subnetworks.use",
    "compute.projects.get"
  ]
}


# Create Balerica custom VPN role
resource "google_project_iam_custom_role" "balerica_vpn_role" {
  provider    = google.balerica
  project     = var.balerica_project # Explicitly
  role_id     = "customVpnAccess"
  title       = "Custom VPN Access Role"
  description = "Allows minimal permissions for VPN gateway usage"
  permissions = google_project_iam_custom_role.genosha_vpn_role.permissions
}


# ===============================================
# Cross-project IAM bindings
# ===============================================

# Allow Balerica SA to use VPN resources
resource "google_project_iam_member" "allow_balerica_on_genosha" {
  provider = google.genosha-ops
  project  = var.genosha_project
  role     = google_project_iam_custom_role.genosha_vpn_role.name
  # role     = "projects/${var.genosha_project}/roles/${google_project_iam_custom_role.balerica_vpn_role.role_id}"
  # member = "serviceAccount:${local.balerica_sa_email}"  
  member = "serviceAccount:${data.google_project.genosha.number}-compute@developer.gserviceaccount.com"

  depends_on = [google_project_iam_custom_role.genosha_vpn_role]
}


# Allow Genosha SA to use Balerica VPN resources
resource "google_project_iam_member" "allow_genosha_on_balerica" {
  provider = google.balerica
  project  = var.balerica_project
  role     = google_project_iam_custom_role.balerica_vpn_role.name
  # member =  "serviceAccount:${local.genosha_sa_email}"
  member = "serviceAccount:${data.google_project.balerica.number}-compute@developer.gserviceaccount.com"

  depends_on = [google_project_iam_custom_role.balerica_vpn_role]
}


/*
# Balerica Custom VPN Role
resource "google_project_iam_custom_role" "balerica_vpn_role" {
  provider    = google.balerica
  project     = var.balerica_project
  role_id     = "customVpnAccess"
  title       = "Custom VPN Access Role"
  description = "Minimal permissions for VPN gateway usage in Balerica"
  permissions = google_project_iam_custom_role.genosha_vpn_role.permissions
}

# ======================================================
# Cross-Project IAM Bindings
# ======================================================

# Allow Balerica SA to use Genosha VPN resources
resource "google_project_iam_member" "allow_balerica_on_genosha" {
  provider = google.genosha-ops
  project  = var.genosha_project
  role     = google_project_iam_custom_role.genosha_vpn_role.name
  member   = "serviceAccount:${local.balerica_sa_email}"

  depends_on = [google_project_iam_custom_role.genosha_vpn_role]
}

# Allow Genosha SA to use Balerica VPN resources
resource "google_project_iam_member" "allow_genosha_on_balerica" {
  provider = google.balerica
  project  = var.balerica_project
  role     = google_project_iam_custom_role.balerica_vpn_role.name
  member   = "serviceAccount:${local.genosha_sa_email}"

  depends_on = [google_project_iam_custom_role.balerica_vpn_role]
}

*/