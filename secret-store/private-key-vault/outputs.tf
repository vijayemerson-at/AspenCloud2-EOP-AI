output "key_vault" {
  value = {
    id                  = azurerm_key_vault.this.id
    resource_group_name = azurerm_key_vault.this.resource_group_name
    tenant_id           = azurerm_key_vault.this.tenant_id
    name                = azurerm_key_vault.this.name
    uri                 = azurerm_key_vault.this.vault_uri
  }
}

output "private_endpoint" {
  value = {
    id = azurerm_private_endpoint.this.id
  }
}
