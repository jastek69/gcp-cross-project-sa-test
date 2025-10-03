# NCC Service Agents - IAM bindings for Service Agents
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account#service-agents

#=====================================================================
# Default Compute Engine Service Accounts for Access to VPN. Temporary accounts
#=====================================================================

# Balerica Project Service Agent

/*
## DEPRECATED ##
This is the old old pattern where Google-managed default Compute Engine SAs handle networking resources.
VPNs depended on the default Compute Engine SAs. 

This has been replace with explicit Terraform SAs and impersonation. 
Current Configuration (with impersonation + Terraform SAs):
  1. Now create / reference explicit Terraform SAs (terraform@taaops.iam.gserviceaccount.com, terraform@genosha-ops.iam.gserviceaccount.com).
  2. Bootstrap them with roleAdmin, create custom VPN roles, and add cross-project IAM bindings between them.
  3. Providers are configured to impersonate those Terraform SAs instead of relying on default compute SAs.


resource "google_project_iam_member" "balerica_ncc_agent" {
  provider = google.genosha-ops
  project  = var.genosha_project
  # role     = "roles/compute.networkUser"
  role   = google_project_iam_custom_role.genosha_vpn_role.name
  member = "serviceAccount:${data.google_project.balerica.number}-compute@developer.gserviceaccount.com"

  depends_on = [google_project_iam_custom_role.genosha_vpn_role]
}



# Genosha Project Service Agent
resource "google_project_iam_member" "genosha_service_agent" {
  provider = google.balerica
  project  = var.balerica_project
  # role     = "roles/compute.networkUser"
  role   = google_project_iam_custom_role.balerica_vpn_role.name
  member = "serviceAccount:${data.google_project.genosha.number}-compute@developer.gserviceaccount.com"

  depends_on = [google_project_iam_custom_role.balerica_vpn_role]
}
*/