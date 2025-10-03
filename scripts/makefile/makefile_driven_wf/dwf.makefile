# ==============================
# Makefile-Driven Workflow
# Makefile for Terraform + GCP SA Impersonation
# Workflow: Bootstrap → verify → switch to impersonation → layer baseline → custom roles → cross-bindings → networking
# This version is an extended Makefile that bundles the full bootstrap → switch → apply sequence
# Makefile-driven script sequence to run all stages with just make bootstrap && make switch && make apply
# ==============================

# ==============================
# 📌 Makefile Cheat Sheet
# ==============================
#
# Workflow Targets (bootstrap/Makefile)
# ------------------------------------------
# make bootstrap            → Apply impersonation bindings (bootstrap_mode=true)
# make switch               → Reminder to flip bootstrap_mode=false & impersonate
# make reset-bootstrap      → Restore Owner role on $(USER_ACCOUNT)
# make teardown             → Destroy all Terraform-managed resources
#
# Doctor Targets (health checks)
# ------------------------------------------
# make doctor-tools         → Check required tools (gcloud, terraform, jq)
# make doctor-light         → Show current gcloud authenticated accounts
# make doctor-debug         → Verify ADC client_email matches $(USER_ACCOUNT)
# make doctor-bootstrap     → Warn if bootstrap_mode=true
# make doctor-enforce-bootstrap → Fail hard if bootstrap_mode=true (CI/CD)
# make doctor               → Run doctor-tools + (doctor-bootstrap or enforce-bootstrap)
# make doctor-all           → Run ALL doctor checks (tools, light, debug, bootstrap)
#
# Terraform Targets (terraform/ directory)
# ------------------------------------------
# make tf-init              → terraform init in terraform/
# make tf-plan              → terraform plan in terraform/
# make tf-apply             → terraform apply in terraform/
# make tf-destroy           → terraform destroy -auto-approve in terraform/
#
# Convenience
# ------------------------------------------
# make all                  → Run doctor-all then terraform plan
#
# ==============================



USER_ACCOUNT      ?= jastek.sweeney@gmail.com
BALERICA_PROJECT  ?= taaops
GENOSHA_PROJECT   ?= genosha-ops
CI                ?= false

# ------------------------------
# Workflow Targets
# ------------------------------

bootstrap:
	@echo "=== [STEP 1] Bootstrap: impersonation bindings ==="
	gcloud auth application-default login
	gcloud projects add-iam-policy-binding $(BALERICA_PROJECT) \
	  --member="user:$(USER_ACCOUNT)" \
	  --role="roles/iam.serviceAccountAdmin"
	gcloud projects add-iam-policy-binding $(GENOSHA_PROJECT) \
	  --member="user:$(USER_ACCOUNT)" \
	  --role="roles/iam.serviceAccountAdmin"
	terraform init
	terraform apply -var="bootstrap_mode=true" \
	  -target=google_service_account_iam_member.balerica_impersonation_token_creator \
	  -target=google_service_account_iam_member.balerica_impersonation_sa_user \
	  -target=google_service_account_iam_member.genosha_impersonation_token_creator \
	  -target=google_service_account_iam_member.genosha_impersonation_sa_user

verify:
	@echo "=== [STEP 2] Verify impersonation ==="
	gcloud auth print-access-token \
	  --impersonate-service-account="terraform@$(BALERICA_PROJECT).iam.gserviceaccount.com" | head -c 80; echo
	gcloud auth print-access-token \
	  --impersonate-service-account="terraform@$(GENOSHA_PROJECT).iam.gserviceaccount.com" | head -c 80; echo

switch:
	@echo "=== [STEP 3] Switch to impersonation mode ==="
	@echo "👉 Update terraform.tfvars to bootstrap_mode=false"
	gcloud auth application-default login

baseline:
	@echo "=== [STEP 4] Apply baseline IAM bindings ==="
	terraform apply -var="bootstrap_mode=false" \
	  -target=google_project_iam_member.balerica_sa_viewer \
	  -target=google_project_iam_member.balerica_sa_network_admin \
	  -target=google_project_iam_member.balerica_sa_ncc_admin \
	  -target=google_project_iam_member.genosha_sa_viewer \
	  -target=google_project_iam_member.genosha_sa_network_admin \
	  -target=google_project_iam_member.genosha_sa_ncc_admin \
	  -target=google_project_iam_member.bootstrap_roleadmin_balerica \
	  -target=google_project_iam_member.bootstrap_roleadmin_genosha

roles:
	@echo "=== [STEP 5] Create custom VPN roles ==="
	terraform apply -var="bootstrap_mode=false" \
	  -target=google_project_iam_custom_role.balerica_vpn_role \
	  -target=google_project_iam_custom_role.genosha_vpn_role

cross:
	@echo "=== [STEP 6] Apply cross-project IAM bindings ==="
	terraform apply -var="bootstrap_mode=false" \
	  -target=google_project_iam_member.allow_balerica_on_genosha \
	  -target=google_project_iam_member.allow_genosha_on_balerica

networking:
	@echo "=== [STEP 7] Apply networking resources ==="
	terraform apply -var="bootstrap_mode=false"

all: bootstrap verify switch baseline roles cross networking
	@echo "✅ Full workflow completed!"
