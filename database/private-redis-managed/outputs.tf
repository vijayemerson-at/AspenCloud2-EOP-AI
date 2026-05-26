output "redis" {
  value = {
    hostname      = azurerm_managed_redis.this.hostname
    port          = azurerm_managed_redis.this.default_database[0].port
    primary_key   = try(azurerm_managed_redis.this.default_database[0].primary_access_key, null)
    secondary_key = try(azurerm_managed_redis.this.default_database[0].secondary_access_key, null)
  }
  sensitive = true
}