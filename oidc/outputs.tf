output "issuer" {
  value = {
    name = google_iam_workload_identity_pool_provider.oidc.workload_identity_pool_provider_id,
    url  = local.issuer_url,
    id   = google_iam_workload_identity_pool_provider.oidc.id
  }
}

output "signing_key_pem" {
  value     = tls_private_key.signing_key.private_key_pem
  sensitive = true
}

output "gcp_bucket_name" {
  value = google_storage_bucket.discovery.name
}
