############################################################
# 03-vpc.tf
# Explicit per-project VPCs (Option A)
############################################################

# ----------------------
# Balerica VPC
# ----------------------
module "balerica_vpc" {
  source = "./modules/vpc"

  providers = {
    google = google.taaops
  }

  project = var.balerica_project
  name    = "${var.balerica_project}-vpc"
}

# ----------------------
# Genosha VPC
# ----------------------
module "genosha_vpc" {
  source = "./modules/vpc"

  providers = {
    google = google.genosha_ops
  }

  project = var.genosha_project
  name    = "${var.genosha_project}-vpc"
}
