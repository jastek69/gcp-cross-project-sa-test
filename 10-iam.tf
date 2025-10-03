# ============================================
# 10-iam.tf
# IAM bindings (baseline + cross-project)
# ============================================

# Baseline roles → every SA in its own project
resource "google_project_iam_member" "baseline_roles" {
  for_each = local.baseline_bindings_map

  project = each.value.project
  member  = "serviceAccount:${each.value.sa}"
  role    = each.value.role
}

# Cross-project impersonation (SA in project X → vpn_role in project Y)
resource "google_project_iam_member" "cross_bindings" {
  for_each = local.cross_bindings_map

  project = each.value.dst
  member  = "serviceAccount:${each.value.sa}"
  role    = "projects/${each.value.dst}/roles/vpn_role"
} 
