data "azurerm_subscription" "current" {}

locals {
  tenant_id                     = var.key_vault.tenant_id != null ? var.key_vault.tenant_id : data.azurerm_subscription.current.tenant_id
  public_network_access_enabled = length(var.key_vault.network_acls.ip_rules) > 0
}

resource "azurerm_key_vault" "this" {
  enable_rbac_authorization       = var.key_vault.enable_rbac_authorization
  enabled_for_deployment          = var.key_vault.enabled_for_deployment
  enabled_for_disk_encryption     = var.key_vault.enabled_for_disk_encryption
  enabled_for_template_deployment = var.key_vault.enabled_for_template_deployment
  location                        = var.location
  name                            = var.key_vault.name
  public_network_access_enabled   = local.public_network_access_enabled
  purge_protection_enabled        = var.key_vault.purge_protection_enabled
  resource_group_name             = var.resource_group_name
  sku_name                        = var.key_vault.sku_name
  soft_delete_retention_days      = var.key_vault.soft_delete_retention_days
  tags                            = merge(var.tags, var.key_vault.tags)
  tenant_id                       = local.tenant_id
  network_acls {
    bypass         = var.key_vault.network_acls.bypass
    default_action = "Deny"
    ip_rules       = var.key_vault.network_acls.ip_rules
  }
}

resource "azurerm_private_endpoint" "this" {
  location            = var.location
  resource_group_name = var.resource_group_name
  name                = "pe-${substr(var.key_vault.name, 0, 77)}"
  subnet_id           = var.private_endpoint.subnet_id

  private_service_connection {
    name                           = "psc-${substr(var.key_vault.name, 0, 76)}"
    private_connection_resource_id = azurerm_key_vault.this.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }
  private_dns_zone_group {
    name                 = "privatelink.vaultcore.azure.net"
    private_dns_zone_ids = var.private_endpoint.private_dns_zone_group.private_dns_zone_ids
  }
  tags = merge(var.tags, var.private_endpoint.tags)
}

resource "azurerm_role_assignment" "admins_object_assignment" {
  count                = length(var.admin_user_object_ids)
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.admin_user_object_ids[count.index]
}

resource "azurerm_role_assignment" "secrets_reader_object_assignment" {
  count                = length(var.secrets_reader_object_ids)
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.secrets_reader_object_ids[count.index]
}
