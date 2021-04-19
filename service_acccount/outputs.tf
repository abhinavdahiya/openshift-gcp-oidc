output service_account_email {
  value = google_service_account.service_account.email
}

output secret {
  value = local.credentials_secret
}