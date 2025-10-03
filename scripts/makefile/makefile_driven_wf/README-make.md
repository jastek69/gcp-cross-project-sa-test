README-make.md

# Makefile-Driven Workflow
#### Workflow: Bootstrap → verify → switch to impersonation → layer baseline → custom roles → cross-bindings → networking

This is an extended Makefile that bundles the full bootstrap → switch → apply sequence. It is a Makefile-driven script sequence to run all stages with just make bootstrap && make switch && make apply.

An extended Makefile that bundles the full bootstrap → switch → apply sequence:

Run it with:

```make all```

Or run each phase individually: make bootstrap, make verify, etc.


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




Glue Approach:

Put Terraform in terraform/ with no Makefile (or a tiny one).
Put your bootstrap/workflow Makefile in bootstrap/.
Add a glue Makefile at root to proxy commands into either.
That way, Terraform devs can just cd terraform && terraform plan, while you still get your make doctor-all etc. at repo root.

# Makefile Glue
project-root/
├── bootstrap/
│   ├── Makefile      # Workflow: bootstrap, doctor, impersonation
│   └── scripts/
└── terraform/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf


How It Works

Bootstrap-related targets (bootstrap, doctor-all, etc.) are proxied to the bootstrap/Makefile.
→ Keeps your workflow logic isolated.

Terraform-related targets (tf-plan, tf-apply, etc.) run Terraform from the terraform/ directory using -chdir.
→ No need for a Makefile inside terraform/.

Combined target (make all) runs full doctor checks and then a terraform plan.

Usage Examples

From the project root:

# Run workflow bootstrap
make bootstrap

# Run doctor checks
make doctor-all

# Run Terraform plan
make tf-plan

# Apply Terraform
make tf-apply


This way, you only ever run make <target> from the root, and the glue file will delegate to the right sub-Makefile or Terraform dir.