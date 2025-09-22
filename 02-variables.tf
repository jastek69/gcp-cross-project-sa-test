

# Test Projects
variable "balerica_project" {
  description = "Balerica Inc, GCP Project ID"
  type        = string
  # default     = "taaops" # Your GCP Project ID{   
}


variable "genosha_project" {
  description = "Genosha Ops, GCP Project ID"
  type        = string
  # default     = "genosha-ops" # Your GCP Project ID
}





# Test Regions
variable "balerica_region" {
  description = "Region for Balerica HA VPN"
  type        = string
}

variable "genosha_region" {
  description = "Region for Genosha HA VPN"
  type        = string
}


# Service Accounts
variable "balerica_sa" {
  type        = string
  description = "Service Account Email for Balerica"
  default = ""
}


variable "genosha_sa" {
  type        = string
  description = "Service Account Email for Genosha"
  default = ""
}



# BGP ASNs for Cloud Routers
# These should be private ASNs in the range 64512 to 65534
variable "balerica_bgp_asn" {
  type        = number
  description = "BGP ASN for Balerica Cloud Router"
}

variable "genosha_bgp_asn" {
  type        = number
  description = "BGP ASN for Genosha Cloud Router"
}


# ================================
# Tunnel 0 IP ranges (/30)
# ================================
variable "balerica_router_ip_tunnel0" {
  type        = string
  description = "Balerica router interface IP for tunnel0"
  default     = "169.254.10.1/30"
}

variable "genosha_router_ip_tunnel0" {
  type        = string
  description = "Genosha router interface IP for tunnel0"
  default     = "169.254.10.2/30"
}

# ================================
# Tunnel 1 IP ranges (/30)
# ================================
variable "balerica_router_ip_tunnel1" {
  type        = string
  description = "Balerica router interface IP for tunnel1"
  default     = "169.254.20.1/30"
}

variable "genosha_router_ip_tunnel1" {
  type        = string
  description = "Genosha router interface IP for tunnel1"
  default     = "169.254.20.2/30"
}








# Pre-shared keys for VPN Tunnels
# These should be set as sensitive variables and not hard-coded in the configuration files
# Pre-shared key for Tunnel 0
variable "tunnel0_psk" {
  description = "Pre-shared key for HA VPN Tunnel 0"
  type        = string
  sensitive   = true
}

# Pre-shared key for Tunnel 1
variable "tunnel1_psk" {
  description = "Pre-shared key for HA VPN Tunnel 1"
  type        = string
  sensitive   = true
}



# JSON credentials paths
variable "balerica_credentials_file" {
  type        = string
  description = "Path to Balerica service account JSON key file"
}

variable "genosha_credentials_file" {
  type        = string
  description = "Path to Genosha service account JSON key file"
}



# Template project variables
variable "project_id1" {
  description = "GCP Project ID"
  type        = string
  default     = "taaops" # Your GCP Project ID
}

variable "project_id2" {
  description = "GCP Project ID"
  type        = string
  default     = "genosha-ops" # Your GCP Project ID
}





variable "tiqs_project" {
  description = "TIQS, GCP Project ID"
  type        = string
  default     = "genosha-ops" # Your GCP Project ID
}


variable "tokyo_project" {
  description = "Tokyo, GCP Project ID"
  type        = string
  default     = "taaops" # Your GCP Project ID  
}




# REGIONS and ZONES




# SINGAPORE - region1 and zone1
variable "region1" {
  description = "GCP Region"
  type        = string
  default     = "asia-southeast1" # Singapore GCP Region
}

variable "zone1" {
  description = "GCP Zone"
  type        = string
  default     = "asia-southeast1-a" # Singapore GCP Zone
}



# SAO PAULO - region2 and zone2
variable "region2" {
  description = "GCP Region"
  type        = string
  default     = "southamerica-east1" # Sao Paulo GCP Region
}

variable "zone2" {
  description = "GCP Zone"
  type        = string
  default     = "southamerica-east1-a" # Sao Paulo GCP Zone
}



# TORONTO - region3 and zone3
variable "region3" {
  description = "GCP Region"
  type        = string
  default     = "northamerica-northeast1" # Toronto GCP Region

}

variable "zone3" {
  description = "GCP Zone"
  type        = string
  default     = "northamerica-northeast1-a" # Toronto GCP Zone
}




#TOKYO - zone5
variable "region5" {
  description = "GCP Region"
  type        = string
  default     = "asia-northeast1" # Tokyo GCP Region  
}

variable "zone5" {
  description = "GCP Zone"
  type        = string
  default     = "asia-northeast1-a" # Tokyo GCP Zone
}




/*

# IAM Policies and Roles
variable "iam_member" {
description = "IAM member to grant roles"
type        = string
default     = "user:your-email@example.com"
}

*/
