
resource "azurerm_eventgrid_domain" "this" {
  location            = var.location
  resource_group_name = var.resource_group_name
  name                = var.eventgrid_domain.name

  identity {
    type         = var.eventgrid_domain.identity.type
    identity_ids = var.eventgrid_domain.identity.identity_ids
  }
  local_auth_enabled = var.eventgrid_domain.local_auth_enabled

  input_schema = var.eventgrid_domain.input_schema
  dynamic "input_mapping_fields" {
    for_each = var.eventgrid_domain.input_mapping_fields[*]
    content {
      id           = input_mapping_fields.id
      topic        = input_mapping_fields.topic
      event_type   = input_mapping_fields.event_type
      data_version = input_mapping_fields.data_version
      subject      = input_mapping_fields.subject
    }
  }
  dynamic "input_mapping_default_values" {
    for_each = var.eventgrid_domain.input_mapping_default_values[*]
    content {
      event_type   = input_mapping_default_values.event_type
      data_version = input_mapping_default_values.data_version
      subject      = input_mapping_default_values.subject
    }
  }
  auto_create_topic_with_first_subscription = var.eventgrid_domain.auto_create_topic_with_first_subscription
  auto_delete_topic_with_last_subscription  = var.eventgrid_domain.auto_delete_topic_with_last_subscription

  public_network_access_enabled = var.eventgrid_domain.public_network_access_enabled
  inbound_ip_rule = [
    for item in var.eventgrid_domain.allowedPublicIpMasks : {
      ip_mask = item
      action  = "Allow"
    }
  ]

  tags = merge(var.tags, var.eventgrid_domain.tags, var.private_endpoint.tags)
}

resource "azurerm_private_endpoint" "this" {
  location            = var.location
  resource_group_name = var.resource_group_name
  name                = "pe-${substr(var.eventgrid_domain.name, 0, 77)}"
  subnet_id           = var.private_endpoint.subnet_id

  private_service_connection {
    name                           = "psc-${substr(var.eventgrid_domain.name, 0, 76)}"
    private_connection_resource_id = azurerm_eventgrid_domain.this.id
    subresource_names              = ["domain"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "eventdomain-group"
    private_dns_zone_ids = var.private_endpoint.private_dns_zone_group.private_dns_zone_ids
  }
  tags = merge(var.tags, var.private_endpoint.tags)
}
