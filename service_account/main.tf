locals {
  external_cred_file = templatefile("${path.module}/external_auth.tpl", {
    token_file_path       = var.secret.token_path,
    service_account_email = google_service_account.service_account.email,
  })

  credentials_secret = yamlencode({
    "apiVersion" : "v1",
    "kind" : "Secret",
    "metadata" : {
      "namespace" : var.secret.namespace,
      "name" : var.secret.name
    }
    "data" : {
      "service-account.json" : base64encode(local.external_cred_file)
    }
  })
}

resource "google_service_account" "service_account" {
  account_id = var.name
}

resource "google_project_iam_member" "permissions" {
  for_each = toset(var.bindings)

  role   = each.key
  member = "serviceAccount:${google_service_account.service_account.email}"
}

data "google_project" "google_project" {}

resource "google_service_account_iam_member" "assume" {
  for_each = toset([for sa in var.service_accounts : "${sa.namespace}::${sa.name}"])

  service_account_id = google_service_account.service_account.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/projects/${data.google_project.google_project.number}/locations/global/workloadIdentityPools/${var.identity_pool}}/subject/${var.iam_namespace}::${each.key}"
}
