# ===========================================================
# Terraform Bootstrap Makefile
# ===========================================================
#
# CICD with Debug
#
# 📝 CHEAT SHEET
#
# Setup / Checks:
#   make doctor-bootstrap        → Check/create Terraform SAs + baseline roles
#   make status-bootstrap        → Show current bootstrap_mode value
#   make toggle-bootstrap MODE=… → Flip bootstrap_mode in terraform.tfvars (true|false)
#
# Bootstrap Flow:
#   make all-bootstrap           → Wrapper: runs doctor + bindings (fail-fast)
#   make bootstrap-sas           → Ensure SAs exist and baseline roles granted
#   make bootstrap-bindings      → Apply impersonation bindings (bootstrap_mode=true)
#   make reset-bootstrap         → Remove bootstrap IAM roles (+DELETE_SA=true optional)
#
# Owner Safety Controls:
#   make restore-owner-only      → Restore Owner role to your Gmail
#   make remove-owner-only       → Remove Owner role from your Gmail
#   make panic-owner-safety      → Panic button: forcibly rebind Owner
#   make status-owner            → Show Owner bindings on both projects
#
# Flags:
#   FORCE=true                   → Bypass confirmation prompts (automation parity)
#   DELETE_SA=true               → Also delete Terraform SAs during reset
#
# ===========================================================
BALERICA_PROJECT ?= taaops
GENOSHA_PROJECT  ?= genosha-ops
BALERICA_REGION  ?= asia-southeast1
GENOSHA_REGION   ?= southamerica-east1
USER_EMAIL       ?= jastek.sweeney@gmail.com

RED    := $(shell tput setaf 1)
GREEN  := $(shell tput setaf 2)
YELLOW := $(shell tput setaf 3)
RESET  := $(shell tput sgr0)

# ===========================================================
# Doctor checks - Bootstrap
# ===========================================================
doctor-bootstrap:
	@echo "=== [DOCTOR] Checking Terraform bootstrap service accounts ==="

	@echo "--- Balerica project ($(BALERICA_PROJECT)) ---"
	@if gcloud iam service-accounts list --project $(BALERICA_PROJECT) \
		--filter="email:terraform@$(BALERICA_PROJECT).iam.gserviceaccount.com" \
		--format="value(email)" | grep -q "terraform@$(BALERICA_PROJECT).iam.gserviceaccount.com"; then \
			echo "$(GREEN)[PASS]$(RESET) Found terraform@$(BALERICA_PROJECT).iam.gserviceaccount.com"; \
		else \
			echo "$(YELLOW)[WARN]$(RESET) Missing SA, creating..."; \
			gcloud iam service-accounts create terraform \
			  --display-name="terraform" \
			  --project=$(BALERICA_PROJECT); \
		fi; \
		echo "🔑 Ensuring minimal + baseline IAM roles..."; \
		for role in roles/iam.serviceAccountAdmin \
		            roles/iam.serviceAccountTokenCreator \
		            roles/viewer \
		            roles/compute.networkAdmin \
		            roles/networkconnectivity.admin; do \
			gcloud projects add-iam-policy-binding $(BALERICA_PROJECT) \
			  --member="serviceAccount:terraform@$(BALERICA_PROJECT).iam.gserviceaccount.com" \
			  --role="$$role" >/dev/null; \
		done

	@echo "--- Genosha project ($(GENOSHA_PROJECT)) ---"
	@if gcloud iam service-accounts list --project $(GENOSHA_PROJECT) \
		--filter="email:terraform@$(GENOSHA_PROJECT).iam.gserviceaccount.com" \
		--format="value(email)" | grep -q "terraform@$(GENOSHA_PROJECT).iam.gserviceaccount.com"; then \
			echo "$(GREEN)[PASS]$(RESET) Found terraform@$(GENOSHA_PROJECT).iam.gserviceaccount.com"; \
		else \
			echo "$(YELLOW)[WARN]$(RESET) Missing SA, creating..."; \
			gcloud iam service-accounts create terraform \
			  --display-name="terraform" \
			  --project=$(GENOSHA_PROJECT); \
		fi; \
		echo "🔑 Ensuring minimal + baseline IAM roles..."; \
		for role in roles/iam.serviceAccountAdmin \
		            roles/iam.serviceAccountTokenCreator \
		            roles/viewer \
		            roles/compute.networkAdmin \
		            roles/networkconnectivity.admin; do \
			gcloud projects add-iam-policy-binding $(GENOSHA_PROJECT) \
			  --member="serviceAccount:terraform@$(GENOSHA_PROJECT).iam.gserviceaccount.com" \
			  --role="$$role" >/dev/null; \
		done

# ===========================================================
# Bootstrap Flow
# ===========================================================
bootstrap-sas: doctor-bootstrap
	@echo "=== [STEP 1] Terraform Service Accounts verified + baseline roles granted ==="

bootstrap-bindings:
	@echo "=== [STEP 2] Apply impersonation bindings (bootstrap_mode=true) ==="
	@if ! grep -q "bootstrap_mode *= *true" terraform.tfvars; then \
	  echo "$(RED)ERROR: bootstrap_mode must be true before running bindings.$(RESET)"; exit 1; \
	fi
	terraform apply -auto-approve \
	  -var="bootstrap_mode=true" \
	  -target=google_service_account_iam_member.balerica_impersonation_token_creator \
	  -target=google_service_account_iam_member.balerica_impersonation_sa_user \
	  -target=google_service_account_iam_member.genosha_impersonation_token_creator \
	  -target=google_service_account_iam_member.genosha_impersonation_sa_user

bootstrap: bootstrap-sas bootstrap-bindings
	@echo "$(GREEN)✅ Bootstrap complete.$(RESET)"
	@echo "👉 Next: set bootstrap_mode=false and re-authenticate with gcloud"

all-bootstrap:
	@echo "=== [ALL-BOOTSTRAP WRAPPER] ==="
	@echo "$(YELLOW)⚠️ Reminder: Run 'gcloud auth application-default login' first, and ensure bootstrap_mode=true.$(RESET)"
	@if ! grep -q "bootstrap_mode *= *true" terraform.tfvars; then \
	  echo "$(RED)ERROR: bootstrap_mode is not true. Aborting.$(RESET)"; exit 1; \
	fi
	$(MAKE) bootstrap-sas
	$(MAKE) bootstrap-bindings
	@echo "$(GREEN)✅ All bootstrap steps complete.$(RESET)"

reset-bootstrap:
	@echo "=== [RESET] Removing bootstrap IAM roles ==="
	@if [ "$(FORCE)" != "true" ]; then \
	  read -p "⚠️  Type 'yes' to confirm reset-bootstrap: " ans; \
	  [ "$$ans" = "yes" ] || { echo "Aborted."; exit 1; }; \
	fi
	@for project in $(BALERICA_PROJECT) $(GENOSHA_PROJECT); do \
	  echo "--- Cleaning $$project ---"; \
	  for role in roles/iam.serviceAccountAdmin \
	               roles/iam.serviceAccountTokenCreator \
	               roles/viewer \
	               roles/compute.networkAdmin \
	               roles/networkconnectivity.admin; do \
	    echo "Removing $$role..."; \
	    gcloud projects remove-iam-policy-binding $$project \
	      --member="serviceAccount:terraform@$$project.iam.gserviceaccount.com" \
	      --role="$$role" || true; \
	  done; \
	  if [ "$(DELETE_SA)" = "true" ]; then \
	    echo "Deleting SA terraform@$$project.iam.gserviceaccount.com..."; \
	    gcloud iam service-accounts delete terraform@$$project.iam.gserviceaccount.com \
	      --project $$project --quiet || true; \
	  else \
	    echo "Skipping SA deletion for $$project (set DELETE_SA=true to force)."; \
	  fi; \
	done
	@echo "$(GREEN)✅ Reset complete.$(RESET)"

# ===========================================================
# Owner Safety Helpers
# ===========================================================
restore-owner-only:
	@echo "=== [OWNER RESTORE] Rebinding Owner to Gmail ($(USER_EMAIL)) ==="
	@if [ "$(FORCE)" != "true" ]; then \
	  read -p "⚠️  Type 'yes' to restore Owner to $(USER_EMAIL): " ans; \
	  [ "$$ans" = "yes" ] || { echo "Aborted."; exit 1; }; \
	fi
	@for project in $(BALERICA_PROJECT) $(GENOSHA_PROJECT); do \
	  gcloud projects add-iam-policy-binding $$project \
	    --member="user:$(USER_EMAIL)" --role="roles/owner" || true; \
	done
	@echo "$(GREEN)✅ Owner role restored.$(RESET)"

remove-owner-only:
	@echo "=== [OWNER REMOVE] Removing Owner from Gmail ($(USER_EMAIL)) ==="
	@if [ "$(FORCE)" != "true" ]; then \
	  read -p "⚠️  Type 'yes' to remove Owner from $(USER_EMAIL): " ans; \
	  [ "$$ans" = "yes" ] || { echo "Aborted."; exit 1; }; \
	fi
	@for project in $(BALERICA_PROJECT) $(GENOSHA_PROJECT); do \
	  gcloud projects remove-iam-policy-binding $$project \
	    --member="user:$(USER_EMAIL)" --role="roles/owner" || true; \
	done
	@echo "$(GREEN)✅ Owner role removed.$(RESET)"

panic-owner-safety:
	@echo "=== [PANIC SAFETY] Resetting Owner to Gmail ($(USER_EMAIL)) ==="
	@if [ "$(FORCE)" != "true" ]; then \
	  read -p "⚠️  Type 'yes' to PANIC RESTORE Owner to $(USER_EMAIL): " ans; \
	  [ "$$ans" = "yes" ] || { echo "Aborted."; exit 1; }; \
	fi
	@for project in $(BALERICA_PROJECT) $(GENOSHA_PROJECT); do \
	  gcloud projects add-iam-policy-binding $$project \
	    --member="user:$(USER_EMAIL)" --role="roles/owner" || true; \
	done
	@echo "$(GREEN)🚨 Owner safety restored (panic button).$(RESET)"

status-owner:
	@echo "=== [OWNER STATUS] Checking Owner bindings ==="
	@for project in $(BALERICA_PROJECT) $(GENOSHA_PROJECT); do \
	  echo "--- $$project ---"; \
	  gcloud projects get-iam-policy $$project \
	    --flatten="bindings[].members" \
	    --filter="bindings.role:roles/owner AND bindings.members:user:$(USER_EMAIL)" \
	    --format="table(bindings.role, bindings.members)" || true; \
	done

panic-owner-safety-wrapper:
	@echo "=== [OWNER SAFETY WRAPPER] ==="
	@if [ "$(FORCE)" != "true" ]; then \
	  echo "$(RED)HARD GUARD: Requires FORCE=true to run this wrapper.$(RESET)"; exit 1; \
	fi
	$(MAKE) restore-owner-only FORCE=true
	$(MAKE) status-owner

# ===========================================================
# Bootstrap Mode Helpers
# ===========================================================
toggle-bootstrap:
	@echo "=== [TOGGLE] Setting bootstrap_mode to $(MODE) ==="
	@if [ "$(MODE)" != "true" ] && [ "$(MODE)" != "false" ]; then \
	  echo "$(RED)ERROR: Must set MODE=true or MODE=false$(RESET)"; exit 1; \
	fi
	@sed -i.bak 's/bootstrap_mode *= *.*/bootstrap_mode = $(MODE)/' terraform.tfvars
	@echo "$(GREEN)✅ bootstrap_mode set to $(MODE).$(RESET)"

status-bootstrap:
	@echo "=== [STATUS] bootstrap_mode ==="
	@grep "bootstrap_mode" terraform.tfvars || echo "$(RED)bootstrap_mode not set$(RESET)"
