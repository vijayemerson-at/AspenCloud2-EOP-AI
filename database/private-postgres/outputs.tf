output "postgresql_flexible_server_id" {
  value = try(azurerm_postgresql_flexible_server.this.id, null)
}

output "postgresql_flexible_server_fqdn" {
  value = try(azurerm_postgresql_flexible_server.this.fqdn, null)
}

output "postgresql_flexible_server_name" {
  value = azurerm_postgresql_flexible_server.this.name
}

output "postgresql_flexible_server_database_names" {
  value = join(", ", [for s in azurerm_postgresql_flexible_server_database.this : s.name])
}

output "postgresql_flexible_server_admin_login" {
  sensitive = true
  value     = azurerm_postgresql_flexible_server.this.administrator_login
}

output "postgresql_flexible_server_admin_password" {
  sensitive = true
  value     = azurerm_postgresql_flexible_server.this.administrator_password
}