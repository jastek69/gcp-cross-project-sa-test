# ==============================================================
# variables.tf
# Centralized variable definitions for Hub/Spoke VPN environment
# ==============================================================

#########################################
# Bootstrap + impersonation
#########################################

# NOTE: bootstrap_mode is declared HERE: in 02-variables.tf
# It toggles authentication mode:
#   true  = ADC (Owner/dev)
#   false = Impersonate Terraform SA
############################################


############################################
# variables.tf
############################################

# Bootstrap toggle
variable "bootstrap_mode" {
  type        = bool
  description = "true = ADC Owner (bootstrap), false = impersonate Terraform SAs"
}

# CICD account (owner email)
variable "cicd_account" {
  type        = string
  description = "CI/CD owner account for bootstrap mode (e.g. user:foo@gmail.com)"
}


# ------------------------------
# Projects
# ------------------------------
variable "balerica_project" { type = string }
variable "balerica_region"  { type = string }
variable "balerica_zone"    { type = string }

variable "genosha_project"  { type = string }
variable "genosha_region"   { type = string }
variable "genosha_zone"     { type = string }

# ------------------------------
# Terraform Service Accounts
# ------------------------------
variable "balerica_sa" {
  type        = string
  description = "Terraform SA for Balerica project"
}

variable "genosha_sa" {
  type        = string
  description = "Terraform SA for Genosha project"
}

# ------------------------------
# Subnets
# ------------------------------
variable "subnet_cidrs" {
  type        = map(string)
  description = "Map of project → subnet CIDR"
}

# ------------------------------
# Spokes
# ------------------------------
variable "spokes" {
  type        = map(string)
  description = "Map of project → Terraform SA"
}

variable "spoke_regions" {
  type        = map(string)
  description = "Map of project → region"
}

# ------------------------------
# VPN Tunnels
# ------------------------------
variable "tunnels" {
  description = "Map of HA VPN tunnel configs"
  type = map(object({
    src        = string
    dst        = string
    region_src = string
    region_dst = string
    asn_src    = number
    asn_dst    = number
    tunnels    = map(object({
      psk     = string
      ip_src  = string
      ip_dst  = string
    }))
  }))
}



#########################################
# Startup Scripts (per project)
#########################################
variable "startup_scripts" {
  description = "Map of project → startup script path"
  type        = map(string)
}
