output "service_account_access_key" {
  description = "Access key for the service account"
  value       = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  sensitive   = true
}

output "service_account_secret_key" {
  description = "Secret key for the service account"
  value       = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  sensitive   = true
}
