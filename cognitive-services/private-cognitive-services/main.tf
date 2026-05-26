resource "azurerm_cognitive_account" "this" {
  location                                     = var.location
  resource_group_name                          = var.resource_group_name
  name                                         = var.cognitive_account.name
  kind                                         = var.cognitive_account.kind
  sku_name                                     = var.cognitive_account.sku_name
  custom_subdomain_name                        = var.cognitive_account.custom_subdomain_name
  dynamic_throttling_enabled                   = var.cognitive_account.dynamic_throttling_enabled
  fqdns                                        = var.cognitive_account.fqdns
  local_auth_enabled                           = var.cognitive_account.local_auth_enabled
  metrics_advisor_aad_client_id                = var.cognitive_account.metrics_advisor_aad_client_id
  metrics_advisor_aad_tenant_id                = var.cognitive_account.metrics_advisor_aad_tenant_id
  metrics_advisor_super_user_name              = var.cognitive_account.metrics_advisor_super_user_name
  metrics_advisor_website_name                 = var.cognitive_account.metrics_advisor_website_name
  outbound_network_access_restricted           = var.cognitive_account.outbound_network_access_restricted
  public_network_access_enabled                = var.cognitive_account.public_network_access_enabled
  qna_runtime_endpoint                         = var.cognitive_account.qna_runtime_endpoint
  custom_question_answering_search_service_id  = var.cognitive_account.custom_question_answering_search_service_id
  custom_question_answering_search_service_key = var.cognitive_account.custom_question_answering_search_service_key

  dynamic "customer_managed_key" {
    for_each = var.cognitive_account.customer_managed_key[*]
    content {
      key_vault_key_id   = var.cognitive_account.customer_managed_key.key_vault_key_id
      identity_client_id = var.cognitive_account.customer_managed_key.identity_client_id
    }
  }

  dynamic "identity" {
    for_each = var.cognitive_account.identity[*]
    content {
      type         = var.cognitive_account.identity.type
      identity_ids = var.cognitive_account.identity.identity_ids
    }
  }

  dynamic "network_acls" {
    for_each = var.cognitive_account.network_acls[*]
    content {
      default_action = var.cognitive_account.network_acls.default_action
      ip_rules       = var.cognitive_account.network_acls.ip_rules
      dynamic "virtual_network_rules" {
        for_each = var.cognitive_account.network_acls.virtual_network_rules[*]
        content {
          subnet_id                            = var.cognitive_account.network_acls.virtual_network_rules.subnet_id
          ignore_missing_vnet_service_endpoint = var.cognitive_account.network_acls.virtual_network_rules.ignore_missing_vnet_service_endpoint
        }
      }
    }
  }

  dynamic "storage" {
    for_each = var.cognitive_account.storage[*]
    content {
      storage_account_id = var.cognitive_account.storage.storage_account_id
      identity_client_id = var.cognitive_account.storage.identity_client_id
    }
  }

  tags = merge(var.tags, var.cognitive_account.tags)
}

resource "azurerm_cognitive_deployment" "deployments" {
  for_each             = { for deployment in var.cognitive_deployments : deployment.name => deployment }
  name                 = each.key
  cognitive_account_id = azurerm_cognitive_account.this.id

  model {
    format  = each.value.model.format
    name    = each.value.model.name
    version = each.value.model.version
  }

  sku {
    name     = each.value.sku.name
    tier     = each.value.sku.tier
    size     = each.value.sku.size
    family   = each.value.sku.family
    capacity = each.value.sku.capacity
  }

  rai_policy_name        = each.value.rai_policy_name
  version_upgrade_option = each.value.version_upgrade_option

  depends_on = [azurerm_cognitive_account.this]
}

resource "azurerm_private_endpoint" "this" {
  location            = var.location
  resource_group_name = var.resource_group_name
  name                = "pe-${substr(var.cognitive_account.name, 0, 77)}"
  subnet_id           = var.private_endpoint.subnet_id

  private_service_connection {
    name                           = "psc-${substr(var.cognitive_account.name, 0, 76)}"
    private_connection_resource_id = azurerm_cognitive_account.this.id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }
  private_dns_zone_group {
    name                 = azurerm_cognitive_account.this.kind == "OpenAI" ? "privatelink.openai.azure.com" : "privatelink.cognitive.account.azure.net"
    private_dns_zone_ids = var.private_endpoint.private_dns_zone_group.private_dns_zone_ids
  }
  tags = merge(var.tags, var.private_endpoint.tags)
}