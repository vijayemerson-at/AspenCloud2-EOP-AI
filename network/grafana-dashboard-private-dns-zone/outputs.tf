output "private_dns_zone" {
  value = {
    id = azurerm_private_dns_zone.this.id
  }
}