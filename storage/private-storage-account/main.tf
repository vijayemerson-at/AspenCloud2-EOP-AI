resource "azurerm_storage_account" "this" {
  resource_group_name              = var.resource_group_name
  location                         = var.location
  name                             = var.storage_account.name
  account_kind                     = var.storage_account.kind
  account_tier                     = var.storage_account.tier
  account_replication_type         = var.storage_account.replication_type
  access_tier                      = var.storage_account.access_tier
  is_hns_enabled                   = var.storage_account.is_hns_enabled
  https_traffic_only_enabled       = true
  public_network_access_enabled    = true
  allow_nested_items_to_be_public  = false
  cross_tenant_replication_enabled = false
  shared_access_key_enabled        = var.storage_account.shared_access_key_enabled

  network_rules {
    # Deny access by default, use "Allow" if you want to allow by default and explicitly deny certain IPs
    default_action = var.storage_account.network_rules.default_action
    ip_rules       = var.storage_account.network_rules.ip_rules # List of public IP or IP ranges in CIDR format
    bypass         = var.storage_account.network_rules.bypass   # Bypass traffic for Azure services

  }

  blob_properties {
    dynamic "cors_rule" {
      for_each = var.storage_account.blob_properties.cors_rule[*]
      content {
        allowed_headers    = cors_rule.value.allowed_headers
        allowed_methods    = cors_rule.value.allowed_methods
        allowed_origins    = cors_rule.value.allowed_origins
        exposed_headers    = cors_rule.value.exposed_headers
        max_age_in_seconds = cors_rule.value.max_age_in_seconds
      }
    }
    delete_retention_policy {
      days                     = var.storage_account.blob_properties.delete_retention_policy.days
      permanent_delete_enabled = var.storage_account.blob_properties.delete_retention_policy.permanent_delete_enabled
    }
    versioning_enabled = var.storage_account.blob_properties.versioning_enabled
  }

  tags = merge(var.tags, var.storage_account.tags)
}

resource "azurerm_storage_account_queue_properties" "this" {
  count = var.storage_account_queue_properties != null && (var.storage_account_queue_properties.cors_rule != null || var.storage_account_queue_properties.hour_metrics != null || var.storage_account_queue_properties.logging != null || var.storage_account_queue_properties.minute_metrics != null) ? 1 : 0

  storage_account_id = azurerm_storage_account.this.id
  dynamic "cors_rule" {
    for_each = var.storage_account_queue_properties.cors_rule[*]
    content {
      allowed_headers    = cors_rule.value.allowed_headers
      allowed_methods    = cors_rule.value.allowed_methods
      allowed_origins    = cors_rule.value.allowed_origins
      exposed_headers    = cors_rule.value.exposed_headers
      max_age_in_seconds = cors_rule.value.max_age_in_seconds
    }
  }

  dynamic "logging" {
    for_each = var.storage_account_queue_properties.logging[*]
    content {
      delete                = logging.value.delete
      read                  = logging.value.read
      version               = logging.value.version
      write                 = logging.value.write
      retention_policy_days = logging.value.retention_policy_days
    }
  }

  dynamic "minute_metrics" {
    for_each = var.storage_account_queue_properties.minute_metrics[*]
    content {
      version               = minute_metrics.value.version
      include_apis          = minute_metrics.value.include_apis
      retention_policy_days = minute_metrics.value.retention_policy_days
    }
  }

  dynamic "hour_metrics" {
    for_each = var.storage_account_queue_properties.hour_metrics[*]
    content {
      version               = hour_metrics.value.version
      include_apis          = hour_metrics.value.include_apis
      retention_policy_days = hour_metrics.value.retention_policy_days
    }
  }
}

resource "azurerm_private_endpoint" "this" {
  for_each = { for idx, pe in var.private_endpoints : idx => pe }

  location            = var.location
  resource_group_name = var.resource_group_name
  name                = "pe-${substr(var.storage_account.name, 0, 60)}-${each.value.private_service_connection.subresource_names[0]}"
  subnet_id           = each.value.subnet_id

  private_service_connection {
    name                           = "psc-${substr(var.storage_account.name, 0, 76)}"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = each.value.private_service_connection.subresource_names
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = each.value.private_dns_zone_group.name
    private_dns_zone_ids = each.value.private_dns_zone_group.private_dns_zone_ids
  }

  tags = merge(var.tags, each.value.tags)
}

resource "azurerm_storage_container" "this" {
  for_each              = { for idx, container in var.storage_containers : idx => container }
  name                  = each.value.name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = each.value.container_access_type
}

resource "azurerm_storage_queue" "this" {
  for_each             = { for idx, queue in var.storage_queues : idx => queue }
  name                 = each.value.name
  storage_account_name = azurerm_storage_account.this.name
}

resource "azurerm_storage_share" "this" {
  for_each           = { for idx, share in var.storage_shares : idx => share }
  name               = each.value.name
  access_tier        = each.value.access_tier
  quota              = each.value.quota
  storage_account_id = azurerm_storage_account.this.id
}
