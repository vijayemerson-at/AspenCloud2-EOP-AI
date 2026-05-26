output "key_vault_name" {
  value = local.keyvault_enabled ? module.kv[0].key_vault.name : null
}

output "key_vault_tenant_id" {
  value = local.keyvault_enabled ? module.kv[0].key_vault.tenant_id : null
}

output "key_vault_identity" {
  value = local.keyvault_enabled ? {
    service_account_namespace = local.service_account_namespace
    service_account_name      = local.service_account_name
    user_assigned_client_id   = azurerm_user_assigned_identity.this[0].client_id
  } : null
}

# Redis connection details (for debugging purposes only - sensitive data in Key Vault)
output "redis_connection_managed" {
  value = local.redis_managed_enabled ? {
    hostname = module.redis_managed[0].redis.hostname
    port     = module.redis_managed[0].redis.port
  } : null
  sensitive   = false
  description = "Managed Redis connection details (non-sensitive)"
}

