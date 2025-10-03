############################################################
# 08a-compute.tf
# Explicit per-project VM deployments
############################################################

# ----------------------------------------------------------
# Balerica VM
# ----------------------------------------------------------
module "balerica_vm" {
  source = "./modules/compute"

  providers = {
    google = google.taaops
  }

  project                = var.balerica_project
  zone                   = var.balerica_zone
  instance_name          = "balerica-vm"
  machine_type           = "n2-standard-2"
  subnetwork             = module.balerica_subnet.subnet_id
  startup_scripts        = var.startup_scripts
  service_account_email  = var.balerica_sa
}

# ----------------------------------------------------------
# Genosha VM
# ----------------------------------------------------------
module "genosha_vm" {
  source = "./modules/compute"

  providers = {
    google = google.genosha_ops
  }

  project                = var.genosha_project
  zone                   = var.genosha_zone
  instance_name          = "genosha-vm"
  machine_type           = "n2-standard-2"
  subnetwork             = module.genosha_subnet.subnet_id
  startup_scripts        = var.startup_scripts
  service_account_email  = var.genosha_sa
}
