# https://developer.hashicorp.com/terraform/language/values/outputs


# Pull the full IAM policy for the Genosha project
data "google_project_iam_policy" "genosha_policy" {
  project = var.genosha_project
}

# Pull the full IAM policy for the Balerica project
data "google_project_iam_policy" "balerica_policy" {
  project = var.balerica_project
}

# Output roles for debugging
output "genosha_sa_roles" {
  value = [
    for binding in data.google_project_iam_policy.genosha_policy.bindings : binding.role
    if contains(binding.members, "serviceAccount:${var.genosha_sa}")
  ]
}

output "balerica_sa_roles" {
  value = [
    for binding in data.google_project_iam_policy.balerica_policy.bindings : binding.role
    if contains(binding.members, "serviceAccount:${var.balerica_sa}")
  ]
}












# output "compute_zones" {
#     description = "values of the compute zones"
#     value       = google_compute_zones.available_zones.names

# }

/*
output "instance_external_ip" {
  value       = "http://${google_compute_instance.planetrock-prod1.network_interface[0].access_config[0].nat_ip}"
  description = "The external IP address of the GCE instance."
}


output "instance_external_ips" {
  value = {
    vm1 = "http://${google_compute_instance.planetrock-prod1.network_interface[0].access_config[0].nat_ip}"
    vm2 = "http://${google_compute_instance.planetrock-prod2.network_interface[0].access_config[0].nat_ip}"
    vm3 = "http://${google_compute_instance.planetrock-prod3.network_interface[0].access_config[0].nat_ip}"
  }
  description = "External IPs of both VMs"
}
*/

/*
output "vpn_gateway_ips" {
  description = "Public IPs of AWS VPN tunnels and GCP VPN gateway"

  value = {
    gcp_gateway_ips = [
      for i in range(length(google_compute_ha_vpn_gateway.balerica-ha-vpn-gw.vpn_interfaces)) : google_compute_ha_vpn_gateway.balerica-ha-vpn-gw.vpn_interfaces[i].ip_address
    ]
  }
}




output "instance_external_ips" {
  value = {
    "${google_compute_instance.balerica-vm.name}" = "http://${google_compute_instance.balerica-vm.network_interface[0].access_config[0].nat_ip}"
    # "${google_compute_instance.taa-vm.name}" = "http://${google_compute_instance.taa-vm.network_interface[0].access_config[0].nat_ip}"    
    # "${google_compute_instance.tiqs-vm.name}"  = "http://${google_compute_instance.tiqs-vm.network_interface[0].access_config[0].nat_ip}"    
  }
  description = "External IPs of all VMs"
}

*/

/*
output "instance_external_zones" {
  value = {
    "${google_compute_instance.balerica-vm.zone}" = "http://${google_compute_instance.balerica-vm.network_interface[0].access_config[0].nat_ip}"
    #  "${google_compute_instance.taa-vm.zone}" = "http://${google_compute_instance.taa-vm.network_interface[0].access_config[0].nat_ip}"
    # "${google_compute_instance.tiqs-vm.zone}" = "http://${google_compute_instance.tiqs-vm.network_interface[0].access_config[0].nat_ip}"
  }
  description = "External IPs of all VMs with their zones"
}


data "google_client_openid_userinfo" "terraform_account" {}
output "current_terraform_account" {
  value = data.google_client_openid_userinfo.terraform_account.email
}
*/


/*
# https://developer.hashicorp.com/terraform/language/functions/join
output "compute_zones" {
  description = "Comma-separated compute zones"
  # convert set into string delimited by commas (CSV) before output
  value       = join(", ", data.google_compute_instance.available.names)
}

output "compute_zones_list" {
  description = "List of compute zones"
  value       = data.google_compute_instance.available.names
}



# ALB Frontend Static IP
output "lb_static_ip_address" {
  description = "The static IP address of the load balancer."
  value       = "http://${google_compute_address.lb.address}"
}


output "debug_paths" {
  value = {
    path_module = path.module
    path_root   = path.root
  }
}
*/