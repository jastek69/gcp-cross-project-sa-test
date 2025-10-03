# ==============================
# Makefile-Driven Workflow version
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
# Makefile for Terraform + GCP SA Impersonation
# ==============================


# ==============================
# 📌 Terraform GCP SA Impersonation Workflow
#
# ┌─────────────────────────────┐
# │ bootstrap_mode = true       │  ← Run as OWNER (your Gmail)
# └──────────────┬──────────────┘
#                │
#                │ make bootstrap
#                ▼
# ┌─────────────────────────────┐
# │ Impersonation bindings set  │  (Gmail/CI/CD → Terraform SAs)
# └──────────────┬──────────────┘
#                │
#                │ make switch
#                ▼
# ┌─────────────────────────────┐
# │ bootstrap_mode = false      │  ← Run as Terraform SAs
# │ (via impersonation)         │
# └──────────────┬──────────────┘
#                │
#                │ Normal Terraform applies
#                ▼
# ┌─────────────────────────────┐
# │ Baseline → Custom Roles →   │
# │ Cross-bindings → Networking │
# └─────────────────────────────┘
#
# 🔑 Keys:
# - bootstrap_mode=true → Terraform uses *your ADC Owner* account
# - bootstrap_mode=false → Terraform uses *impersonated SAs*
#
# Common targets:
#   make login            → Hint: gcloud auth ADC login as Gmail Owner
#   make bootstrap        → Apply impersonation bindings (seed chain)
#   make switch           → Reminder: flip bootstrap_mode=false
#   make doctor-all       → Run all health checks (tools, ADC, bootstrap)
#   make reset-bootstrap  → Restore Owner role on Gmail if locked out
#   make teardown         → Destroy all Terraform-managed resources
# ==============================




# --- Default Variables ---
USER_ACCOUNT      ?= jastek.sweeney@gmail.com
BALERICA_PROJECT  ?= taaops
GENOSHA_PROJECT   ?= genosha-ops
CI                ?= false

# ==============================
# Targets
# ==============================

## ---- Authentication ----

login:
	@echo "=== [login] Authentication hint ==="
	@echo "Run the following manually in your shell:"
	@echo "    gcloud auth application-default login"
	@echo ""
	@echo "👉 Then set bootstrap_mode=true in terraform.tfvars for bootstrap phase."
	@echo "👉 Later, flip to bootstrap_mode=false after impersonation is seeded."

## ---- Bootstrap Phase ----
bootstrap:
	@echo "=== [STEP 1] Bootstrap: impersonation bindings (bootstrap_mode=true) ==="
	terraform init
	terraform apply \
	  -var="bootstrap_mode=true" \
	  -target=google_service_account_iam_member.balerica_impersonation_token_creator \
	  -target=google_service_account_iam_member.balerica_impersonation_sa_user \
	  -target=google_service_account_iam_member.genosha_impersonation_token_creator \
	  -target=google_service_account_iam_member.genosha_impersonation_sa_user

switch:
	@echo "=== [STEP 2] Switch to impersonation (bootstrap_mode=false) ==="
	@echo "👉 Edit terraform.tfvars and set:"
	@echo "    bootstrap_mode = false"
	@echo ""
	@echo "Then run:"
	@echo "    terraform apply"

reset-bootstrap:
	@echo "=== Reset Bootstrap: Restore Owner on $(USER_ACCOUNT) ==="
	gcloud projects add-iam-policy-binding $(BALERICA_PROJECT) \
	  --member="user:$(USER_ACCOUNT)" \
	  --role="roles/owner"
	gcloud projects add-iam-policy-binding $(GENOSHA_PROJECT) \
	  --member="user:$(USER_ACCOUNT)" \
	  --role="roles/owner"

## ---- Teardown ----
teardown:
	@echo "=== Teardown: Destroy all Terraform resources ==="
	terraform destroy -auto-approve

## ---- Doctor (Health Checks) ----
doctor-tools:
	@echo "=== [doctor-tools] Checking required tools ==="
	@which gcloud >/dev/null || (echo "❌ gcloud not found" && exit 1)
	@which terraform >/dev/null || (echo "❌ terraform not found" && exit 1)
	@which jq >/dev/null || (echo "❌ jq not found" && exit 1)
	@echo "✅ Tools check passed"

doctor-light:
	@echo "=== [doctor-light] Running light auth check ==="
	@gcloud auth list

doctor-debug:
	@echo "=== [doctor-debug] Debugging ADC client_email ==="
	@if [ -f "$$APPDATA/gcloud/application_default_credentials.json" ]; then \
		file="$$APPDATA/gcloud/application_default_credentials.json"; \
	elif [ -f "$$HOME/.config/gcloud/application_default_credentials.json" ]; then \
		file="$$HOME/.config/gcloud/application_default_credentials.json"; \
	else \
		echo "❌ No ADC credentials file found"; exit 1; \
	fi; \
	email=$$(jq -r .client_email $$file); \
	echo "🔑 Found client_email: $$email (from $$file)"; \
	if [ "$$email" != "$(USER_ACCOUNT)" ]; then \
		echo "❌ Mismatch: expected $(USER_ACCOUNT)"; exit 1; \
	fi; \
	echo "✅ client_email matches $(USER_ACCOUNT)"

doctor-bootstrap:
	@echo "=== [doctor-bootstrap] Checking bootstrap mode ==="
	@if grep -q "bootstrap_mode *= *true" terraform.tfvars; then \
		echo "⚠️  WARNING: bootstrap_mode=true (running with Owner ADC)"; \
	else \
		echo "✅ bootstrap_mode=false (running under impersonation)"; \
	fi

doctor-enforce-bootstrap:
	@echo "=== [doctor-enforce-bootstrap] CI/CD strict bootstrap check ==="
	@if grep -q "bootstrap_mode *= *true" terraform.tfvars; then \
		echo "❌ ERROR: bootstrap_mode=true is forbidden in CI/CD"; exit 1; \
	else \
		echo "✅ bootstrap_mode=false"; \
	fi


# Colors
GREEN := $(shell tput setaf 2)
RED   := $(shell tput setaf 1)
YELLOW:= $(shell tput setaf 3)
RESET := $(shell tput sgr0)

doctor-all:
	@echo "=== [doctor-all] Running ALL doctor checks ==="
	@fails=""; passes=""; warnings=""; \
	\
	echo "=== [doctor-tools] ==="; \
	if $(MAKE) --no-print-directory doctor-tools; then \
		echo "$(GREEN)PASS$(RESET): tools"; \
		passes="$$passes tools "; \
	else \
		echo "$(RED)FAIL$(RESET): tools"; \
		fails="$$fails tools "; \
	fi; \
	\
	echo "=== [doctor-light] ==="; \
	if $(MAKE) --no-print-directory doctor-light; then \
		echo "$(GREEN)PASS$(RESET): light"; \
		passes="$$passes light "; \
	else \
		echo "$(RED)FAIL$(RESET): light"; \
		fails="$$fails light "; \
	fi; \
	\
	echo "=== [doctor-debug] ==="; \
	if $(MAKE) --no-print-directory doctor-debug; then \
		echo "$(GREEN)PASS$(RESET): debug"; \
		passes="$$passes debug "; \
	else \
		echo "$(RED)FAIL$(RESET): debug"; \
		fails="$$fails debug "; \
	fi; \
	\
	echo "=== [doctor-bootstrap] ==="; \
	if $(MAKE) --no-print-directory doctor-bootstrap; then \
		echo "$(GREEN)PASS$(RESET): bootstrap"; \
		passes="$$passes bootstrap "; \
	else \
		echo "$(YELLOW)WARN$(RESET): bootstrap"; \
		warnings="$$warnings bootstrap "; \
	fi; \
	\
	echo "--------------------------------------------"; \
	if [ -z "$$fails" ]; then \
		if [ "$(CI)" = "true" ]; then \
			bootstrap=$$(terraform output -json 2>/dev/null | jq -r '.bootstrap_mode.value // empty'); \
			if [ "$$bootstrap" = "true" ]; then \
				echo "$(RED)❌ CI MODE: bootstrap_mode=true is not allowed in pipelines$(RESET)"; \
				exit 1; \
			fi; \
		fi; \
		echo "$(GREEN)✅ ALL CRITICAL CHECKS PASSED$(RESET)"; \
	else \
		echo "$(RED)❌ SOME CHECKS FAILED$(RESET)"; \
	fi; \
	echo "   $(GREEN)Passed$(RESET):   $$passes"; \
	echo "   $(YELLOW)Warnings$(RESET): $$warnings"; \
	echo "   $(RED)Failed$(RESET):   $$fails"; \
	[ -z "$$fails" ]