locals {
  issuer_url = "https://storage.googleapis.com/${google_storage_bucket.discovery.name}"

  discovery_json = jsonencode({
    "issuer" : local.issuer_url,
    "jwks_uri" : "${local.issuer_url}/keys.json",
    "authorization_endpoint" : "urn:kubernetes:programmatic_authorization",
    "response_types_supported" : [
      "id_token"
    ],
    "subject_types_supported" : [
      "public"
    ],
    "id_token_signing_alg_values_supported" : [
      "RS256"
    ],
    "claims_supported" : [
      "sub",
      "iss"
    ]
  })
}

resource "google_storage_bucket" "discovery" {
  name = "${var.name}-oidc-discovery"

  uniform_bucket_level_access = true
}

resource "google_storage_bucket_access_control" "discovery_public_rule" {
  bucket = google_storage_bucket.discovery.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_storage_bucket_object" "discovery_json" {
  name    = ".well-known/openid-configuration"
  content = local.discovery_json
  bucket  = "google_storage_bucket.discovery.name"
}

resource "google_storage_bucket_object" "keys_json" {
  name   = "keys.json"
  source = "${path.module}/keys.json"
  bucket = "google_storage_bucket.discovery.name"

  depends_on = [
    null_resource.keys_json_file
  ]
}

resource "google_iam_workload_identity_pool_provider" "oidc" {
  provider                           = google-beta
  workload_identity_pool_id          = var.identity_pool
  workload_identity_pool_provider_id = "${var.name}-oidc"

  attribute_mapping = {
    "google.subject" = "\"${var.name}.svc.id.openshift[\" + assertion['kubernetes.io'].namespace + \"/\" + assertion['kubernetes.io'].serviceaccount.name + \"]\""
  }

  oidc {
    allowed_audiences = ["openshift"]
    issuer_uri        = local.issuer_url
  }

}
