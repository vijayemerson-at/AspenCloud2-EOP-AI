resource "azurerm_managed_redis" "this" {
  name                = var.redis.name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku_name = var.redis.sku_name

  high_availability_enabled = true

  public_network_access = var.redis.public_network_access

  identity {
    type         = try(var.redis.identity.type, "SystemAssigned")
    identity_ids = try(var.redis.identity.identity_ids, null)
  }

  tags = merge(var.tags, var.redis.tags)

  dynamic "customer_managed_key" {
    for_each = var.redis.customer_managed_key[*]

    content {
      key_vault_key_id          = customer_managed_key.value.key_vault_key_id
      user_assigned_identity_id = customer_managed_key.value.user_assigned_identity_id
    }
  }

  default_database {
    access_keys_authentication_enabled = var.redis.default_database.access_keys_authentication_enabled

    client_protocol   = var.redis.client_protocol
    clustering_policy = var.redis.clustering_policy
    eviction_policy   = var.redis.eviction_policy

    persistence_append_only_file_backup_frequency = var.redis.persistence_append_only_file_backup_frequency
    persistence_redis_database_backup_frequency   = var.redis.persistence_redis_database_backup_frequency
  }
}

resource "azurerm_private_endpoint" "this" {
  name                = "pe-${substr(var.redis.name, 0, 77)}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint.subnet_id

  private_service_connection {
    name                           = "psc-${substr(var.redis.name, 0, 76)}"
    private_connection_resource_id = azurerm_managed_redis.this.id
    is_manual_connection           = false
    subresource_names              = ["redisEnterprise"]
  }

  private_dns_zone_group {
    name                 = "privatelink.redis.azure.net"
    private_dns_zone_ids = var.private_endpoint.private_dns_zone_group.private_dns_zone_ids
  }

  tags = merge(var.tags, var.private_endpoint.tags)
}