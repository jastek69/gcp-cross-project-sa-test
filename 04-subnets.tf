############################################################
# 04-subnets.tf
# Explicit per-project Subnets (Option A)
############################################################

# ----------------------
# Balerica Subnet
# ----------------------
module "balerica_subnet" {
  source = "./modules/subnet"

  providers = {
    google = google.taaops
  }

  project = var.balerica_project
  region  = var.balerica_region
  cidr    = var.subnet_cidrs["taaops"]
  network = module.balerica_vpc.vpc_self_link
  name    = "${var.balerica_project}-subnet"
}

# ----------------------
# Genosha Subnet
# ----------------------
module "genosha_subnet" {
  source = "./modules/subnet"

  providers = {
    google = google.genosha_ops
  }

  project = var.genosha_project
  region  = var.genosha_region
  cidr    = var.subnet_cidrs["genosha-ops"]
  network = module.genosha_vpc.vpc_self_link
  name    = "${var.genosha_project}-subnet"
}
