# Manual Bootstrap Flow (Consolidated)

### **Step 1. Authenticate as Yourself (Owner)**

`gcloud auth application-default login`

- This writes an ADC JSON (`application_default_credentials.json`) for your **personal Owner Gmail**.
    
- Terraform will temporarily use **your Gmail identity** to create IAM bindings.
    

---

### **Step 2. Ensure Bootstrap User Can Manage SAs**

Terraform needs to call `getIamPolicy` on service accounts, which requires `Service Account Admin` at project level.

Grant yourself that once per project:

`# Balerica gcloud projects add-iam-policy-binding taaops \   --member="user:jastek.sweeney@gmail.com" \   --role="roles/iam.serviceAccountAdmin"  # Genosha gcloud projects add-iam-policy-binding genosha-ops \   --member="user:jastek.sweeney@gmail.com" \   --role="roles/iam.serviceAccountAdmin"`

---

### **Step 3. Apply Only the Impersonation Bindings**

Tell Terraform “just build impersonation links”:

`terraform init  terraform apply \   -var="bootstrap_mode=true" \   -target=google_service_account_iam_member.balerica_impersonation_token_creator \   -target=google_service_account_iam_member.balerica_impersonation_sa_user \   -target=google_service_account_iam_member.genosha_impersonation_token_creator \   -target=google_service_account_iam_member.genosha_impersonation_sa_user`

---

### **Step 4. Verify Impersonation Works**

`# Balerica gcloud auth print-access-token \   --impersonate-service-account=terraform@taaops.iam.gserviceaccount.com | head -c 80; echo  # Genosha gcloud auth print-access-token \   --impersonate-service-account=terraform@genosha-ops.iam.gserviceaccount.com | head -c 80; echo`

✅ If you see a `ya29...` token string → impersonation works.

---

### **Step 5. Switch to Normal Mode**

Flip the toggle back:

`bootstrap_mode = false`

Then re-authenticate as your **dev/CI/CD account** (not Owner):

`gcloud auth application-default login`

From this point forward, **Terraform providers impersonate the Terraform service accounts** via:

`provider "google" {   impersonate_service_account = local.balerica_sa_email }`

---

### **Step 6. Apply Baseline IAM + Temporary RoleAdmin**

Give the impersonated SAs enough power to manage infra:

`terraform apply \   -target=google_project_iam_member.balerica_sa_viewer \   -target=google_project_iam_member.balerica_sa_network_admin \   -target=google_project_iam_member.balerica_sa_ncc_admin \   -target=google_project_iam_member.genosha_sa_viewer \   -target=google_project_iam_member.genosha_sa_network_admin \   -target=google_project_iam_member.genosha_sa_ncc_admin \   -target=google_project_iam_member.bootstrap_roleadmin_balerica \   -target=google_project_iam_member.bootstrap_roleadmin_genosha`

---

### **Step 7. Create Custom VPN Roles**

`terraform apply \   -target=google_project_iam_custom_role.balerica_vpn_role \   -target=google_project_iam_custom_role.genosha_vpn_role`

---

### **Step 8. Apply Cross-Bindings**

`terraform apply \   -target=google_project_iam_member.allow_balerica_on_genosha \   -target=google_project_iam_member.allow_genosha_on_balerica`

---

### **Step 9. Apply Networking**

Now IAM is in place → apply everything:

`terraform apply`

---

## 🔑 Key Takeaways

- `bootstrap_mode = true` is just a **temporary shortcut** to bypass impersonation until you can seed impersonation itself.
    
- Your **personal Owner** account must run Step 3 because only it can add the impersonation bindings.
    
- After Step 5, you never run Terraform as Owner again. Everything flows through impersonated SAs.


#
#
#
#
#
#



# Makefile Flow
# Manual Bootstrap Workflow (Refined)

## 1. Authenticate as Yourself (Bootstrap Mode)

Set **bootstrap mode ON** so Terraform uses _your_ credentials:

`# terraform.tfvars bootstrap_mode = true`

Then login as your **Gmail Owner account**:

`gcloud auth application-default login`

This writes ADC credentials under:

- **Windows:** `%APPDATA%\gcloud\application_default_credentials.json`
    
- **Linux/Mac:** `~/.config/gcloud/application_default_credentials.json`
    

---

## 2. Ensure You Have Bootstrap Permissions

Manually grant yourself `Service Account Admin` in both projects:

`gcloud projects add-iam-policy-binding taaops \   --member="user:jastek.sweeney@gmail.com" \   --role="roles/iam.serviceAccountAdmin"  gcloud projects add-iam-policy-binding genosha-ops \   --member="user:jastek.sweeney@gmail.com" \   --role="roles/iam.serviceAccountAdmin"`

This is required so Terraform can call `getIamPolicy` on SAs.

---

## 3. Seed Impersonation Bindings

Apply only the impersonation IAM resources:

`make bootstrap`

(Under the hood this runs `terraform apply -target=...` for the 4 impersonation bindings.)

---

## 4. Verify Impersonation Works

Check that you can mint access tokens for the Terraform SAs:

`gcloud auth print-access-token \   --impersonate-service-account="terraform@${BALERICA_PROJECT}.iam.gserviceaccount.com" \   | head -c 80; echo  gcloud auth print-access-token \   --impersonate-service-account="terraform@${GENOSHA_PROJECT}.iam.gserviceaccount.com" \   | head -c 80; echo`

If you see `ya29....` tokens, impersonation works.

---

## 5. Switch to Normal Mode

Flip back to impersonation mode:

`# terraform.tfvars bootstrap_mode = false`

Re-authenticate with your **dev/CI/CD account**:

`gcloud auth application-default login`

Now all Terraform providers impersonate the project SAs.

---

## 6. Baseline + Temporary Bootstrap Roles

Apply the baseline SA roles plus temporary RoleAdmin bindings:

`make baseline`

---

## 7. Create Custom VPN Roles

`make custom-roles`

---

## 8. Cross-Project Bindings

`make cross-bindings`

---

## 9. Networking Resources

Finally, apply all networking resources (VPCs, routers, VPNs, spokes, etc.):

`make all`

---

## 10. Diagnostics

Use the doctor targets if something feels off:

- `make doctor` → full info
    
- `make doctor-light` → quick auth check
    
- `make doctor-debug` → validates ADC client_email, checks impersonation





Makefile - How It Works
1. Run gcloud auth application-default login outside of make
2. make bootstrap → now depends on login
(so login runs first, then bootstrap bindings are applied)
* make switch → prints the command to flip back to impersonation
* make reset-bootstrap → restores roles/owner on your Gmail
* make teardown → destroys all resources
* make doctor-* → runs health/debug/bootstrap checks


Makefile Flow:
Set **bootstrap mode ON** so Terraform uses _your_ credentials:
`# terraform.tfvars bootstrap_mode = true`

1. Login manually (Login as your **Gmail Owner account**) run:
gcloud auth application-default login

2. make bootstrap → depends on login
(so login runs first, then bootstrap bindings are applied)

3. make switch → prints the command to flip back to impersonation

4. make reset-bootstrap → restores roles/owner on your Gmail

5. make teardown → destroys all resources

6. make doctor-* → runs health/debug/bootstrap checks



Manual Makefile Flow
Bootstrap phase (Owner mode)

This is where you seed impersonation.

Set bootstrap mode ON

# terraform.tfvars
bootstrap_mode = true


→ Terraform will use your ADC credentials (your Gmail Owner account) directly, not impersonation.

Login manually as Owner

gcloud auth application-default login


This updates your application_default_credentials.json so Terraform runs as your Gmail.

Run the bootstrap target

make bootstrap


Depends on make login (prints the hint).

Runs terraform init.

Applies the impersonation bindings (lets your Gmail/CI/CD impersonate the Terraform SAs).

Switch to impersonation

Now Terraform should stop running as Owner and instead impersonate the Terraform SAs.

Run the switch target

make switch


Just prints a reminder:

Flip bootstrap_mode=false in terraform.tfvars.

Re-run terraform apply so providers use impersonation.

Maintenance / Recovery targets

For cleanup or fixing access.

Reset bootstrap

make reset-bootstrap


Restores roles/owner on your Gmail account in both projects.

Safety net if you lock yourself out.

Teardown

make teardown


Destroys all Terraform-managed resources.

Doctor checks

Useful for verifying health, debugging, and enforcing policies.

Doctor checks

make doctor-tools       # tools installed? gcloud/terraform/jq
make doctor-light       # show who’s logged in with gcloud
make doctor-debug       # ADC client_email matches USER_ACCOUNT
make doctor-bootstrap   # warn if bootstrap_mode=true
make doctor-all         # run all checks with summary banner


In CI/CD pipelines:

CI=true make doctor


→ Fails hard if bootstrap_mode=true.

🔑 Key idea

bootstrap_mode=true → Use your Gmail (Owner) to seed impersonation.

bootstrap_mode=false → Use impersonated Terraform SAs going forward.