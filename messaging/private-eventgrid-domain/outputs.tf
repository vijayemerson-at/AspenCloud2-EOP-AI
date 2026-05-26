output "eventgrid_domain" {
  value = {
    id                   = azurerm_eventgrid_domain.this.id
    name                 = azurerm_eventgrid_domain.this.name
    resource_group_name  = azurerm_eventgrid_domain.this.resource_group_name
    endpoint             = azurerm_eventgrid_domain.this.endpoint
    primary_access_key   = azurerm_eventgrid_domain.this.primary_access_key
    secondary_access_key = azurerm_eventgrid_domain.this.secondary_access_key
    identity             = azurerm_eventgrid_domain.this.identity
    principal_id         = azurerm_eventgrid_domain.this.identity[0].principal_id
  }
}

output "private_endpoint" {
  value = {
    id = azurerm_private_endpoint.this.id
  }
}
