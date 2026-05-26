output "storage_account" {
  value = {
    id                               = azurerm_storage_account.this.id
    resource_group_name              = azurerm_storage_account.this.resource_group_name
    name                             = azurerm_storage_account.this.name
    primary_blob_endpoint            = azurerm_storage_account.this.primary_blob_endpoint
    primary_queue_endpoint           = azurerm_storage_account.this.primary_queue_endpoint
    primary_access_key               = azurerm_storage_account.this.primary_access_key
    primary_connection_string        = azurerm_storage_account.this.primary_connection_string
    secondary_access_key             = azurerm_storage_account.this.secondary_access_key
    secondary_connection_string      = azurerm_storage_account.this.secondary_connection_string
    primary_blob_connection_string   = azurerm_storage_account.this.primary_blob_connection_string
    secondary_blob_connection_string = azurerm_storage_account.this.secondary_blob_connection_string
  }
}

# This will give you something like: { "blob": { "id": "<id1>" }, "queue": { "id": "<id2>" } }
output "private_endpoint" {
  value = { for idx, pe in azurerm_private_endpoint.this : one(one(pe.private_service_connection).subresource_names[*]) => { id = pe.id } }
}

output "storage_containers" {
  value       = { for idx, container in azurerm_storage_container.this : container.name => { id = container.id } }
  description = "A map of storage container names to their details including Azure Resource Manager IDs."
}
