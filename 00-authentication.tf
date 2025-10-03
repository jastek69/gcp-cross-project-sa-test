#############################################################
# Authentication + Mode Toggle
#
# bootstrap_mode = true  → Use ADC (your Gmail owner account)
# bootstrap_mode = false → Impersonate Terraform SAs
#############################################################

############################################
# 00-authentication.tf
# NOTE: bootstrap_mode is declared in 02-variables.tf
# It toggles authentication mode:
#   true  = ADC (Owner/dev)
#   false = Impersonate Terraform SA
############################################

# Providers for wiring provider blocks

