# Cross-Project HA VPN

This setup will ideally use cross-project HA VPN in order to avoid the default Compute Engine SAs which is the ideal "good" security practice. It relies only on the explicit service accounts that Terraform itself creates and manages.
  * Each project (Balerica + Genosha) has its own Terraform service account.
  * Custom IAM roles (e.g. customVpnAccess) are created in each project with only the minimum permissions.
  * Cross-project IAM bindings then allow each SA to use VPN resources in the other project.
  * depends_on ensures that Terraform doesn’t try to bind roles to SAs or apply permissions before the underlying roles/SAs exist.


* Both sides (05a + 05b) define their own HA VPN Gateway
* 2 tunnels per side (tunnel0, tunnel1)

Each tunnel has:
  * Router interface (ip_range = var.*_router_ip_tunnel*)
  * Router peer (peer_ip_address = split("/", var.*_router_ip_tunnel*)[0])
  * Peers use split("/", var.*_router_ip_tunnel0)[0] (peer IP only)

  Split Explanation:  
  peer_ip_address = split("/", var.genosha_router_ip_tunnel0)[0]

  var.genosha_router_ip_tunnel0 is defined in your .tfvars like this:       
        genosha_router_ip_tunnel0 = "169.254.10.2/30"

  That’s a CIDR string (IP address + subnet mask).But BGP Peers only want the raw IP address, not the mask.

  split("/", var.genosha_router_ip_tunnel0) → ["169.254.10.2", "30"]
    [0] selects the first element → "169.254.10.2"

  This strips off the subnet mask and gives you just the peer IP address. That way, your router interface still uses the full x.x.x.x/30, but the peer uses just the x.x.x.x.


All PSKs + ASNs come from .tfvars
ASNs are pulled from balerica_bgp_asn and genosha_bgp_asn
  * Router ASN = 65501 (Balerica)
  * Peer ASN = 65515 (Genosha)


#Full dependency chain: IAM → Gateways → Tunnels → Interfaces → Peers

Terraform follows: IAM ➝ VPN Gateways ➝ Tunnels ➝ Router Interfaces ➝ Router Peers

This ensures the following:
    * Service accounts are created with short account_id = "terraform".
    * .tfvars overrides (balerica_sa, genosha_sa) can be used if you want pre-existing SAs.
    * Locals unify the references (local.balerica_sa_email, local.genosha_sa_email).
    * Custom roles grant minimal VPN permissions.
    * IAM bindings always reference the correct service account.
    * depends_on enforces role creation before bindings.




🔹Role of the HA VPN Gateway
  * google_compute_ha_vpn_gateway represents the physical HA VPN endpoint in each project/region.
  * The tunnels (google_compute_vpn_tunnel) are always anchored to a gateway.
  * Without the gateway, Terraform has nowhere to attach the tunnels.


🔹 How They Fit in the Config

  Your dependency chain looks like this:
    * IAM Bindings (google_project_iam_member) → allow cross-project SA usage
    * HA VPN Gateways (google_compute_ha_vpn_gateway) → the actual VPN endpoints
    * Routers (google_compute_router) → BGP-capable routers in each project
    * Tunnels (google_compute_vpn_tunnel) → attach to the gateways and routers
    * Router Interfaces (google_compute_router_interface) → bind tunnels to router IPs
    * Router Peers (google_compute_router_peer) → configure the BGP sessions


HA VPN Mesh with Explicit Traffic Selectors - ASCII Diagram 
                     ┌─────────────────────────┐
                     │     Balerica Project     │
                     │ Region: asia-southeast1  │
                     │ ASN: 65501               │
                     └───────────┬─────────────┘
                                 │
                 ┌───────────────┼─────────────────┐
                 │                                   │
        ┌────────▼────────┐                ┌────────▼────────┐
        │ HA VPN GW (if0) │                │ HA VPN GW (if1) │
        │ balerica        │                │ balerica        │
        └───────┬─────────┘                └───────┬─────────┘
                │                                  │
      Tunnel0   │                                  │   Tunnel1
(local TS=0.0.0.0/0)                     (local TS=0.0.0.0/0)
(remote TS=0.0.0.0/0)                    (remote TS=0.0.0.0/0)
                │                                  │
   169.254.10.1 │                                  │ 169.254.20.1
        ┌───────▼────────┐                ┌────────▼───────┐
        │ Router Intf T0 │                │ Router Intf T1 │
        │ 169.254.10.1/30│                │169.254.20.1/30 │
        └───────┬────────┘                └───────┬────────┘
                │                                  │
                │                                  │
        ┌───────▼────────┐                ┌────────▼───────┐
        │ BGP Peer (T0)  │                │ BGP Peer (T1)  │
        │ ASN 65515      │                │ ASN 65515      │
        └────────────────┘                └────────────────┘

                 <<======== Encrypted VPN Tunnels ========>>

        ┌────────────────┐                ┌────────────────┐
        │ BGP Peer (T0)  │                │ BGP Peer (T1)  │
        │ ASN 65501      │                │ ASN 65501      │
        └───────┬────────┘                └───────┬────────┘
   169.254.10.2 │                                  │ 169.254.20.2
        ┌───────▼────────┐                ┌────────▼───────┐
        │ Router Intf T0 │                │ Router Intf T1 │
        │ 169.254.10.2/30│                │169.254.20.2/30 │
        └───────┬────────┘                └───────┬────────┘
                │                                  │
      Tunnel0   │                                  │   Tunnel1
(local TS=0.0.0.0/0)                     (local TS=0.0.0.0/0)
(remote TS=0.0.0.0/0)                    (remote TS=0.0.0.0/0)
                │                                  │
        ┌───────▼────────┐                ┌────────▼────────┐
        │ HA VPN GW (if0)│                │ HA VPN GW (if1) │
        │ genosha        │                │ genosha         │
        └───────────┬────┘                └───────┬─────────┘
                    │                            │
                     └───────────────┬───────────┘
                                     │
                     ┌───────────────▼─────────────┐
                     │     Genosha Project         │
                     │ Region: southamerica-east1  │
                     │ ASN: 65515                  │
                     └─────────────────────────────┘





🔹 GCP Best Practice

Google recommends 1 router per region, per unique ASN relationship.

Hub-and-spoke - run one router at the hub and let it peer with multiple spokes’ routers — that’s supported and scales well with this confiuration.

Only add multiple routers in the hub project if you need administrative isolation or different ASN policies per spoke.


👉 later expand Balerica into a hub with multiple spoke projects, you can either:

* Keep a single hub router in Balerica, or
* Create 1 router per spoke if you want more granular control.




### Troubleshooting IAM SA permissions:

## 🔑 Step 1: Org Admin Grants You `roles/iam.roleAdmin`

This is **not something Terraform can “import” directly**. Permissions live in IAM policies at the **project, folder, or org level** and are attached to *your user* or *your Terraform service account*.

If your org admins grant:

```
roles/iam.roleAdmin

```

to:

- **you** (your Google account), or
- the **Terraform service account** you’re using,

then Terraform will automatically gain the ability to **create and manage custom roles**.

Nothing to import — the new permission just takes effect when you rerun `terraform apply`.

---

## 🔑 Step 2: Verify Permissions

From your local machine, check:

```bash
gcloud projects get-iam-policy genosha-ops \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members:terraform@genosha-ops.iam.gserviceaccount.com"

```

You should see `roles/iam.roleAdmin` (and any other roles granted) in the output.

---

## 🔑 Step 3: Using It in Terraform

If your SA has `roles/iam.roleAdmin`, you don’t need to change your Terraform code — the `google_project_iam_custom_role` resource will just succeed.

Example from your `iam.tf`:

```hcl
resource "google_project_iam_custom_role" "genosha_vpn_role" {
  provider    = google.genosha-ops
  project     = var.genosha_project
  role_id     = "customVpnAccess"
  title       = "Custom VPN Access Role"
  description = "Allows minimal permissions for VPN gateway usage"

  permissions = [
    "compute.vpnGateways.use",
    "compute.vpnTunnels.create",
    "compute.vpnTunnels.delete",
    "compute.vpnTunnels.get",
    "compute.vpnTunnels.list",
    "compute.routers.use",
    "compute.networks.use",
    "compute.subnetworks.use",
    "compute.projects.get"
  ]
}

```

Terraform doesn’t “import” IAM privileges; it just **relies on your current credentials** to create/update resources.

---

## 🔑 Step 4: Alternative if Org Denies RoleAdmin

If your org won’t grant `roles/iam.roleAdmin`, you cannot manage custom roles in Terraform. Options:

- Use **built-in roles** like `roles/compute.networkAdmin` or `roles/compute.xpnAdmin`.
- Or ask admins to **create the custom role once**, then you use `data "google_iam_role"` to reference it without managing it.

see what IAM roles your Terraform service account (`terraform@genosha-ops.iam.gserviceaccount.com`) has. The correct syntax is:

```bash
gcloud projects get-iam-policy genosha-ops \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members:serviceAccount:terraform@genosha-ops.iam.gserviceaccount.com"

```

Notice two important differences:

1. **Prefix `serviceAccount:` is required** in the filter string. Without it, gcloud won’t match properly.
2. `terraform@genosha-ops.iam.gserviceaccount.com` must exactly match the service account email in your project.

---

## 🔎 If the Command Still Fails

- Make sure you’re authenticated to the correct project:
    
    ```bash
    gcloud config set project genosha-ops
    
    ```
    
- Check if you can view IAM policies at all (you need `roles/viewer` or higher):
    
    ```bash
    gcloud projects get-iam-policy genosha-ops --format=json | jq .
    
    ```
    
    If this fails, your user doesn’t have permission to view IAM on that project.
    

---

## 🛠 Next Step

Once you confirm the command works, look for:

- `roles/iam.roleAdmin` → means you can create custom roles with Terraform.
- If missing, you’ll need to request it from your org admins.

### Option 1: View in JSONrun to output a list of roles granted to your Terraform service account.

```python
gcloud projects get-iam-policy genosha-ops \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:terraform@genosha-ops.iam.gserviceaccount.com" \
  --format="table(bindings.role)"

```

### Option 2: View in JSON

```bash
gcloud projects get-iam-policy genosha-ops --format=json

```

You can scroll through the JSON and look for entries under `"bindings"` where `"members"` includes:

```
"serviceAccount:terraform@genosha-ops.iam.gserviceaccount.com"

```

---

### Option 3: YAML (easier to read than JSON)

```bash
gcloud projects get-iam-policy genosha-ops --format=yaml

```

---

### 🔎 What to Look For

If you see something like:

```yaml
- members:
  - serviceAccount:terraform@genosha-ops.iam.gserviceaccount.com
  role: roles/iam.roleAdmin

```

✅ That means your SA can create custom roles.

If you **don’t** see `roles/iam.roleAdmin`, then Terraform will fail when applying `google_project_iam_custom_role` resources.

### How to grant the Terraform service account the **`roles/iam.roleAdmin`** permission directly in Google Cloud IAM.

---

## 🔑 Option 1: Using `gcloud` CLI

Run this command to give your Terraform service account `roles/iam.roleAdmin`:

```bash
gcloud projects add-iam-policy-binding taaops \
  --member="serviceAccount:terraform@taaops.iam.gserviceaccount.com" \
  --role="roles/iam.roleAdmin"

```

Or if you want your **user account** (your own email) to have it:

```bash
gcloud projects add-iam-policy-binding taaops \
  --member="user:your.email@example.com" \
  --role="roles/iam.roleAdmin"

```

---

## 🔑 Option 2: Via Google Cloud Console

1. Go to IAM & Admin → IAM.
2. Select the **taaops** project.
3. Find your service account (`terraform@taaops.iam.gserviceaccount.com`) or your own user.
4. Click **Edit principal**.
5. Click **Add role** → Search for **Role Administrator**.
6. Save.

---

## 🔎 Verify Assignment

Once added, you can verify with:

```bash
gcloud projects get-iam-policy taaops \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:terraform@taaops.iam.gserviceaccount.com" \
  --format="table(bindings.role)"

```

You should now see:

```
ROLE
roles/iam.roleAdmin

```

---

⚠️ **Security Note**:

`roles/iam.roleAdmin` is powerful — it lets the SA create and update *any* custom role in the project. For production security, you might restrict this to **Terraform’s dedicated project** only, not globally.

## Terraform Bootstrap code for temporary roles/iam.roleadmin

- IAM bootstraps with RoleAdmin → custom roles → cross-project bindings.
- Gateways wait until bootstrap is finished.
- Tunnels wait until gateways + bindings are finalized.
- Interfaces wait on tunnels.
- Peers wait on interfaces.
- This ensures the mesh only builds once the IAM security foundation is in place, and that elevated privileges are revoked afterwards.

## 🔑 Flow

1. **Bootstrap phase**:
    
    Terraform gives its SAs `roles/iam.roleAdmin` just long enough to create `customVpnAccess` roles.
    
2. **Custom roles created**:
    
    Terraform builds `customVpnAccess` in both projects and applies cross-project bindings.
    
3. **Tear-down phase**:
    
    Once bindings are in place, Terraform removes the `roles/iam.roleAdmin` grants.
    
    → Your SA is left with only the custom role assignments.
    

---

## ⚠️ Caveat

- Removing `roles/iam.roleAdmin` means that **future role edits** will fail unless you re-add it temporarily.
- A safer alternative: keep `roleAdmin` only in **development** projects and strip it out in **production**.


 
Use this command to grant cross-project permissions outside of Terraform:

**Cross-Project VPN Gateway Permissions**

For Genosha (genosha-ops) to use Balerica's VPN Gateway:

# Get Balerica's service account email
BALERICA_SA=$(jq -r .client_email taaops-e9943412868a.json)

# Grant permissions in Genosha project
gcloud projects add-iam-policy-binding genosha-ops \
  --member="serviceAccount:${BALERICA_SA}" \
  --role="roles/compute.networkAdmin"


# Get Genosha's service account email
GENOSHA_SA=$(jq -r .client_email genosha-ops-78a3599fb148.json)

# Grant permissions in Balerica project
gcloud projects add-iam-policy-binding taaops \
  --member="serviceAccount:${GENOSHA_SA}" \
  --role="roles/compute.networkAdmin"

  

**Grant Project IAM Admin role to the service account:**

# For Genosha project
gcloud projects add-iam-policy-binding genosha-ops \
  --member="serviceAccount:${GENOSHA_SA}" \
  --role="roles/resourcemanager.projectIamAdmin"

# For Balerica project
gcloud projects add-iam-policy-binding taaops \
  --member="serviceAccount:${BALERICA_SA}" \
  --role="roles/resourcemanager.projectIamAdmin"
