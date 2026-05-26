data "azurerm_client_config" "current" {}

locals {
  public_network_access_enabled = length(var.allowed_cidrs) > 0
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  resource_group_name           = var.resource_group_name
}

##-----------------------------------------------------------------------------
## This resource will create postgresql flexible server.
##-----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server" "this" {
  name                   = var.postgresql_flexible_server.name
  administrator_login    = var.postgresql_flexible_server.administrator_login
  administrator_password = var.postgresql_flexible_server.administrator_password
  dynamic "authentication" {
    for_each = var.postgresql_flexible_server.authentication[*]
    content {
      active_directory_auth_enabled = authentication.value.active_directory_auth_enabled
      password_auth_enabled         = authentication.value.password_auth_enabled
      tenant_id                     = authentication.value.tenant_id
    }
  }
  backup_retention_days = var.postgresql_flexible_server.backup_retention_days
  dynamic "customer_managed_key" {
    for_each = var.postgresql_flexible_server.customer_managed_key[*]
    content {
      key_vault_key_id                     = customer_managed_key.value.key_vault_key_id
      primary_user_assigned_identity_id    = customer_managed_key.value.primary_user_assigned_identity_id
      geo_backup_key_vault_key_id          = customer_managed_key.value.geo_backup_key_vault_key_id
      geo_backup_user_assigned_identity_id = customer_managed_key.value.geo_backup_user_assigned_identity_id
    }
  }
  geo_redundant_backup_enabled = var.postgresql_flexible_server.geo_redundant_backup_enabled
  create_mode                  = var.postgresql_flexible_server.create_mode
  delegated_subnet_id          = var.postgresql_flexible_server.delegated_subnet_id
  private_dns_zone_id          = var.postgresql_flexible_server.private_dns_zone_id
  dynamic "high_availability" {
    for_each = var.postgresql_flexible_server.high_availability[*]
    content {
      mode                      = high_availability.value.mode
      standby_availability_zone = high_availability.value.standby_availability_zone
    }
  }
  dynamic "identity" {
    for_each = var.postgresql_flexible_server.identity[*]
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
  location = var.location
  dynamic "maintenance_window" {
    for_each = var.postgresql_flexible_server.maintenance_window[*]
    content {
      day_of_week  = maintenance_window.value.day_of_week
      start_hour   = maintenance_window.value.start_hour
      start_minute = maintenance_window.value.start_minute
    }
  }
  point_in_time_restore_time_in_utc = var.postgresql_flexible_server.point_in_time_restore_time_in_utc
  public_network_access_enabled     = local.public_network_access_enabled
  replication_role                  = var.postgresql_flexible_server.replication_role
  resource_group_name               = var.resource_group_name
  sku_name                          = var.postgresql_flexible_server.sku_name
  source_server_id                  = var.postgresql_flexible_server.source_server_id
  auto_grow_enabled                 = var.postgresql_flexible_server.auto_grow_enabled
  storage_mb                        = var.postgresql_flexible_server.storage_mb
  storage_tier                      = var.postgresql_flexible_server.storage_tier
  tags                              = merge(var.tags, var.postgresql_flexible_server.tags)
  version                           = var.postgresql_flexible_server.version
  zone                              = var.postgresql_flexible_server.zone
}

##-----------------------------------------------------------------------------
## This resource will create Firewall rule that allow access from Azure services
##-----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure" {
  count            = var.allow_azure_services_ips ? 1 : 0
  name             = "allow-access-from-azure-services"
  server_id        = azurerm_postgresql_flexible_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

##-----------------------------------------------------------------------------
## This resource will create Firewall rule that allow access for all IPs
##-----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_firewall_rule" "all" {
  count            = var.allow_all_ips ? 1 : 0
  name             = "allow-all-ips"
  server_id        = azurerm_postgresql_flexible_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

##-----------------------------------------------------------------------------
## This resource will create Firewall rule that allow access for certain IPs
##-----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_firewall_rule" "ip_range" {
  for_each         = var.allowed_cidrs
  name             = each.key
  server_id        = azurerm_postgresql_flexible_server.this.id
  start_ip_address = cidrhost(each.value, 0)
  end_ip_address   = cidrhost(each.value, -1)
}

##-----------------------------------------------------------------------------
## This resource will create PostgreSQL flexible database.
##-----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_database" "this" {
  for_each  = toset(var.databases)
  name      = each.value.name
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = each.value.charset
  collation = each.value.collation

  lifecycle {
    //FYI, To mitigate the possibility of accidental data loss it is highly recommended that you use the prevent_destroy lifecycle argument in your configuration file for this resource
    prevent_destroy = true
  }

  depends_on = [azurerm_postgresql_flexible_server.this]
}

##------------------------------------------------------------------------
## Allows you to set a PostgreSQL configuration value on a Azure PostgreSQL Flexible Server.
## There are 433 flexibleServers/configurations https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration
##------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_configuration" "this" {
  for_each = var.server_configurations

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = each.value

  depends_on = [azurerm_postgresql_flexible_server.this]
}

##------------------------------------------------------------------------
## Allows you to set users or groups as AD administrators for a PostgreSQL Flexible Server.
##------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "this" {
  for_each = {
    for idx, pg_admin in var.active_directory_administrators : idx => pg_admin
    if var.postgresql_flexible_server.authentication.active_directory_auth_enabled
  }
  server_name         = azurerm_postgresql_flexible_server.this.name
  resource_group_name = local.resource_group_name
  tenant_id           = local.tenant_id
  object_id           = each.value.object_id
  principal_name      = each.value.principal_name
  principal_type      = each.value.principal_type
}

resource "azurerm_private_endpoint" "this" {
  location            = var.location
  resource_group_name = var.resource_group_name
  name                = "pe-${substr(var.postgresql_flexible_server.name, 0, 77)}"
  subnet_id           = var.private_endpoint.subnet_id

  private_service_connection {
    name                           = "psc-${substr(var.postgresql_flexible_server.name, 0, 76)}"
    private_connection_resource_id = azurerm_postgresql_flexible_server.this.id
    is_manual_connection           = false
    subresource_names              = ["postgresqlServer"]
  }
  private_dns_zone_group {
    name                 = "privatelink.postgres.database.azure.com"
    private_dns_zone_ids = var.private_endpoint.private_dns_zone_group.private_dns_zone_ids
  }
  tags = merge(var.tags, var.private_endpoint.tags)
}