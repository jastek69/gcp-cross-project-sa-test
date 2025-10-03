# ==============================
# Root Makefile (Glue)
# ==============================

# Defaults
USER_ACCOUNT      ?= jastek.sweeney@gmail.com
BALERICA_PROJECT  ?= taaops
GENOSHA_PROJECT   ?= genosha-ops
CI                ?= false

# ------------------------------
# Proxy into bootstrap/ workflow
# ------------------------------
bootstrap:
	@$(MAKE) -C bootstrap bootstrap

switch:
	@$(MAKE) -C bootstrap switch

reset-bootstrap:
	@$(MAKE) -C bootstrap reset-bootstrap

teardown:
	@$(MAKE) -C bootstrap teardown

doctor:
	@$(MAKE) -C bootstrap doctor

doctor-all:
	@$(MAKE) -C bootstrap doctor-all

doctor-debug:
	@$(MAKE) -C bootstrap doctor-debug

doctor-light:
	@$(MAKE) -C bootstrap doctor-light

doctor-bootstrap:
	@$(MAKE) -C bootstrap doctor-bootstrap

doctor-enforce-bootstrap:
	@$(MAKE) -C bootstrap doctor-enforce-bootstrap

# ------------------------------
# Proxy into terraform/
# ------------------------------
tf-init:
	terraform -chdir=terraform init

tf-plan:
	terraform -chdir=terraform plan

tf-apply:
	terraform -chdir=terraform apply

tf-destroy:
	terraform -chdir=terraform destroy -auto-approve

# ------------------------------
# Convenience Targets
# ------------------------------
all: doctor-all tf-plan
	@echo "✅ Doctor checks complete, Terraform plan ready."
