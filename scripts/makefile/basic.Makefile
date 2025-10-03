# ==============================
# Makefile for Terraform + GCP SA Impersonation
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




# --- Default Variables ---
USER_ACCOUNT      ?= jastek.sweeney@gmail.com
BALERICA_PROJECT  ?= taaops
GENOSHA_PROJECT   ?= genosha-ops
CI                ?= false

# Colors
GREEN  := $(shell tput setaf 2)
RED    := $(shell tput setaf 1)
YELLOW := $(shell tput setaf 3)
RESET  := $(shell tput sgr0)

# ------------------------------
# Bootstrap Phase
# ------------------------------

bootstrap:
	@echo "=== Bootstrap: Apply impersonation bindings with bootstrap_mode=true ==="
	terraform init
	terraform apply \
	  -var="bootstrap_mode=true" \
	  -target=google_service_account_iam_member.balerica_impersonation_token_creator \
	  -target=google_service_account_iam_member.balerica_impersonation_sa_user \
	  -target=google_service_account_iam_member.genosha_impersonation_token_creator \
	  -target=google_service_account_iam_member.genosha_impersonation_sa_user

switch:
	@echo "=== Switch: Flip bootstrap_mode=false and impersonate Terraform SAs ==="
	@echo "👉 Run: terraform apply -var='bootstrap_mode=false'"

reset-bootstrap:
	@echo "=== Reset Bootstrap: Restore Owner on $(USER_ACCOUNT) ==="
	gcloud projects add-iam-policy-binding $(BALERICA_PROJECT) \
	  --member="user:$(USER_ACCOUNT)" \
	  --role="roles/owner"
	gcloud projects add-iam-policy-binding $(GENOSHA_PROJECT) \
	  --member="user:$(USER_ACCOUNT)" \
	  --role="roles/owner"

# ------------------------------
# Teardown
# ------------------------------

teardown:
	@echo "=== Teardown: Destroy all Terraform resources ==="
	terraform destroy -auto-approve

# -------------------------------
# Doctor (Health Checks)
# -------------------------------
doctor-tools:
	@echo "🔍 Checking required tools..."
	@which gcloud >/dev/null && echo "$(GREEN)✅ gcloud found$(RESET)" || (echo "$(RED)❌ gcloud not found$(RESET)" && exit 1)
	@which terraform >/dev/null && echo "$(GREEN)✅ terraform found$(RESET)" || (echo "$(RED)❌ terraform not found$(RESET)" && exit 1)
	@which jq >/dev/null && echo "$(GREEN)✅ jq found$(RESET)" || (echo "$(RED)❌ jq not found$(RESET)" && exit 1)

doctor-light:
	@echo "🔍 Running light auth check..."
	@gcloud auth list

doctor-debug:
	@echo "🔍 Debugging ADC client_email..."
	@if [ -f "$$APPDATA/gcloud/application_default_credentials.json" ]; then \
		file="$$APPDATA/gcloud/application_default_credentials.json"; \
	elif [ -f "$$HOME/.config/gcloud/application_default_credentials.json" ]; then \
		file="$$HOME/.config/gcloud/application_default_credentials.json"; \
	else \
		echo "$(RED)❌ No ADC credentials file found$(RESET)"; exit 1; \
	fi; \
	email=$$(jq -r .client_email $$file); \
	echo "🔑 Found client_email: $$email (from $$file)"; \
	if [ "$$email" != "$(USER_ACCOUNT)" ]; then \
		echo "$(RED)❌ Mismatch: expected $(USER_ACCOUNT)$(RESET)"; exit 1; \
	fi; \
	echo "$(GREEN)✅ client_email matches $(USER_ACCOUNT)$(RESET)"

doctor-bootstrap:
	@echo "🔍 Checking bootstrap mode..."
	@if grep -q "bootstrap_mode *= *true" terraform.tfvars; then \
		echo "$(YELLOW)⚠️  WARNING: bootstrap_mode=true (running with Owner ADC)$(RESET)"; \
	else \
		echo "$(GREEN)✅ bootstrap_mode=false (running under impersonation)$(RESET)"; \
	fi

doctor-enforce-bootstrap:
	@echo "🔍 Enforcing bootstrap mode (CI/CD strict check)..."
	@if grep -q "bootstrap_mode *= *true" terraform.tfvars; then \
		echo "$(RED)❌ ERROR: bootstrap_mode=true is forbidden in CI/CD$(RESET)"; exit 1; \
	else \
		echo "$(GREEN)✅ bootstrap_mode=false$(RESET)"; \
	fi

doctor:
	@if [ "$(CI)" = "true" ]; then \
		$(MAKE) doctor-tools && $(MAKE) doctor-enforce-bootstrap; \
	else \
		$(MAKE) doctor-tools && $(MAKE) doctor-bootstrap; \
	fi

doctor-all:
	@echo "🔍 Running ALL doctor checks..."
	@fails=""; \
	passes=""; \
	\
	echo "=== [doctor-tools] ==="; \
	if $(MAKE) --no-print-directory doctor-tools; then \
		passes="$$passes tools "; \
	else \
		fails="$$fails tools "; \
	fi; \
	\
	echo "=== [doctor-light] ==="; \
	if $(MAKE) --no-print-directory doctor-light; then \
		passes="$$passes light "; \
	else \
		fails="$$fails light "; \
	fi; \
	\
	echo "=== [doctor-debug] ==="; \
	if $(MAKE) --no-print-directory doctor-debug; then \
		passes="$$passes debug "; \
	else \
		fails="$$fails debug "; \
	fi; \
	\
	echo "=== [doctor-bootstrap] ==="; \
	if $(MAKE) --no-print-directory doctor-bootstrap; then \
		passes="$$passes bootstrap "; \
	else \
		fails="$$fails bootstrap "; \
	fi; \
	\
	echo "--------------------------------------------"; \
	if [ -z "$$fails" ]; then \
		if [ "$$CI" = "true" ]; then \
			bootstrap=$$(terraform output -json 2>/dev/null | jq -r '.bootstrap_mode.value // empty'); \
			if [ "$$bootstrap" = "true" ]; then \
				echo "$(RED)❌ CI MODE: bootstrap_mode=true is not allowed in pipelines$(RESET)"; \
				exit 1; \
			fi; \
		fi; \
		echo "$(GREEN)✅ ALL CHECKS PASSED: ($$passes)$(RESET)"; \
	else \
		echo "$(RED)❌ SOME CHECKS FAILED$(RESET)"; \
		echo "   $(GREEN)Passed:$$passes$(RESET)"; \
		echo "   $(RED)Failed:$$fails$(RESET)"; \
		exit 1; \
	fi
