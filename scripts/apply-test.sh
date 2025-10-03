#!/usr/bin/env bash
set -euo pipefail

# =====================================================================
# apply-test.sh
# Safe staged Terraform apply for HA VPN + Router infra
# =====================================================================

# Colors for better visibility
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

echo -e "${YELLOW}>>> Running terraform init (if not already initialized)...${NC}"
terraform init -reconfigure

echo -e "${YELLOW}>>> Step 1: Apply IAM + VPCs (baseline only)${NC}"
terraform plan -out=step1.tfplan \
  -target=module.balerica_vpc \
  -target=module.genosha_vpc \
  -target=google_project_iam_member.baseline_roles \
  -target=google_project_iam_member.cross_bindings
terraform apply step1.tfplan

echo -e "${GREEN}✓ Step 1 complete: IAM + VPCs provisioned.${NC}\n"

# ---------------------------------------------------------------------
echo -e "${YELLOW}>>> Step 2: Apply HA VPN Gateways${NC}"
terraform plan -out=step2.tfplan \
  -target=google_compute_ha_vpn_gateway.gateways
terraform apply step2.tfplan

echo -e "${GREEN}✓ Step 2 complete: HA VPN Gateways provisioned.${NC}\n"

# ---------------------------------------------------------------------
echo -e "${YELLOW}>>> Step 3: Apply VPN Tunnels${NC}"
terraform plan -out=step3.tfplan \
  -target=google_compute_vpn_tunnel.all
terraform apply step3.tfplan

echo -e "${GREEN}✓ Step 3 complete: VPN Tunnels created.${NC}\n"

# ---------------------------------------------------------------------
echo -e "${YELLOW}>>> Step 4: Apply Routers, Interfaces, and Peers${NC}"
terraform plan -out=step4.tfplan \
  -target=google_compute_router.routers \
  -target=google_compute_router_interface.interfaces \
  -target=google_compute_router_peer.peers
terraform apply step4.tfplan

echo -e "${GREEN}✓ Step 4 complete: Routers, interfaces, and peers configured.${NC}\n"

# ---------------------------------------------------------------------
echo -e "${YELLOW}>>> Step 5: Final converge (apply everything)${NC}"
terraform plan -out=final.tfplan
terraform apply final.tfplan

echo -e "${GREEN}✓ All stages complete! Your HA VPN infra is deployed.${NC}"
