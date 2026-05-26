output "cognitive_account" {
  value = {
    id                   = azurerm_cognitive_account.this.id
    name                 = azurerm_cognitive_account.this.name
    endpoint             = azurerm_cognitive_account.this.endpoint
    location             = azurerm_cognitive_account.this.location
    identity             = azurerm_cognitive_account.this.identity
    primary_access_key   = azurerm_cognitive_account.this.primary_access_key
    secondary_access_key = azurerm_cognitive_account.this.secondary_access_key
  }
}

output "cognitive_deployments" {
  description = "A map of deployment names to their Ids."
  value = {
    for idx, deployment in azurerm_cognitive_deployment.deployments : deployment.name => { id = deployment.id }
  }
}

output "private_endpoint" {
  value = {
    id = azurerm_private_endpoint.this.id
  }
}