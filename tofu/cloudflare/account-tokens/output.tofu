output "all_available_permissions" {
  description = "A map of all available API Account token permission groups and their IDs."
  value       = data.cloudflare_account_permission_groups.all.result
}
