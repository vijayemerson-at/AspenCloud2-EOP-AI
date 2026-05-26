output "key_vault_name" {
  value = local.keyvault_enabled ? module.kv[0].key_vault.name : null
}

output "key_vault_tenant_id" {
  value = local.keyvault_enabled ? module.kv[0].key_vault.tenant_id : null
}

output "key_vault_identity" {
  value = local.keyvault_enabled ? {
    service_accounts        = local.service_accounts
    user_assigned_client_id = azurerm_user_assigned_identity.this[0].client_id
  } : null
}

