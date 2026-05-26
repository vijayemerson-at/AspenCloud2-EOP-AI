resource "azurerm_private_dns_zone" "this" {
  name                = "privatelink.${var.location}.prometheus.monitor.azure.com"
  resource_group_name = var.resource_group_name
  tags                = merge(var.tags, var.private_dns_zone.tags)
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "monitor-workspace-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = var.private_dns_zone_virtual_network_link.virtual_network_id
  tags                  = merge(var.tags, var.private_dns_zone_virtual_network_link.tags)
}