## ---------------------------------------------------
# Managed Prometheus
## ---------------------------------------------------
resource "azurerm_monitor_workspace" "this" {
  name                          = var.monitor_workspace.name
  resource_group_name           = var.resource_group.name
  location                      = var.location
  public_network_access_enabled = var.monitor_workspace.public_network_access_enabled

  tags = merge(var.tags, var.monitor_workspace.tags)
}

## ---------------------------------------------------
# Managed Grafana
## ---------------------------------------------------
resource "azurerm_dashboard_grafana" "this" {
  name                                   = var.dashboard_grafana.name
  resource_group_name                    = var.resource_group.name
  location                               = var.location
  grafana_major_version                  = var.dashboard_grafana.grafana_major_version
  api_key_enabled                        = var.dashboard_grafana.api_key_enabled
  auto_generated_domain_name_label_scope = var.dashboard_grafana.auto_generated_domain_name_label_scope
  deterministic_outbound_ip_enabled      = var.dashboard_grafana.deterministic_outbound_ip_enabled

  dynamic "smtp" {
    for_each = var.dashboard_grafana.smtp[*]

    content {
      enabled                   = var.dashboard_grafana.enabled
      host                      = var.dashboard_grafana.host
      user                      = var.dashboard_grafana.user
      password                  = var.dashboard_grafana.password
      start_tls_policy          = var.dashboard_grafana.start_tls_policy
      from_address              = var.dashboard_grafana.from_address
      from_name                 = var.dashboard_grafana.from_name
      verification_skip_enabled = var.dashboard_grafana.verification_skip_enabled
    }
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.this.id
  }

  dynamic "identity" {
    for_each = var.dashboard_grafana.identity[*]

    content {
      type         = var.dashboard_grafana.identity.type
      identity_ids = var.dashboard_grafana.identity.identity_ids
    }
  }

  public_network_access_enabled = var.dashboard_grafana.public_network_access_enabled
  sku                           = var.dashboard_grafana.sku
  zone_redundancy_enabled       = var.dashboard_grafana.zone_redundancy_enabled

  tags = merge(var.tags, var.dashboard_grafana.tags)
}

resource "azurerm_monitor_data_collection_endpoint" "this" {
  name                = "dce-${var.monitor_workspace.name}"
  resource_group_name = var.resource_group.name
  location            = var.location
  kind                = "Linux"

  tags = merge(var.tags, var.monitor_workspace.tags)
}

resource "azurerm_monitor_data_collection_rule" "this" {
  name                        = "dcr-${var.monitor_workspace.name}"
  resource_group_name         = var.resource_group.name
  location                    = var.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.this.id
  kind                        = "Linux"

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.this.id
      name               = "MonitoringAccount1"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount1"]
  }

  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "PrometheusDataSource"
    }
  }

  description = "DCR for Azure Monitor Metrics Profile (Managed Prometheus)"

  tags = merge(var.tags, var.monitor_workspace.tags)

  depends_on = [
    azurerm_monitor_data_collection_endpoint.this
  ]
}

resource "azurerm_monitor_data_collection_rule_association" "this" {
  name                    = "dcra-${var.monitor_workspace.name}"
  target_resource_id      = var.kubernetes_cluster.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.this.id
  description             = "Association of data collection rule. Deleting this association will break the data collection for this AKS Cluster."

  depends_on = [
    azurerm_monitor_data_collection_rule.this
  ]
}

resource "azurerm_private_endpoint" "monitor_workspace" {
  location            = var.location
  resource_group_name = var.resource_group.name
  name                = "pe-${substr(var.monitor_workspace.name, 0, 77)}"
  subnet_id           = var.monitor_workspace_private_endpoint.subnet_id

  private_service_connection {
    name                           = "psc-${substr(var.monitor_workspace.name, 0, 76)}"
    private_connection_resource_id = azurerm_monitor_workspace.this.id
    is_manual_connection           = false
    subresource_names              = ["prometheusMetrics"]
  }

  private_dns_zone_group {
    name                 = "privatelink.${var.location}.prometheus.monitor.azure.com"
    private_dns_zone_ids = var.monitor_workspace_private_endpoint.private_dns_zone_group.private_dns_zone_ids
  }

  tags = merge(var.tags, var.monitor_workspace_private_endpoint.tags)
}

resource "azurerm_private_endpoint" "dashboard_grafana" {
  location            = var.location
  resource_group_name = var.resource_group.name
  name                = "pe-${substr(var.dashboard_grafana.name, 0, 77)}"
  subnet_id           = var.dashboard_grafana_private_endpoint.subnet_id

  private_service_connection {
    name                           = "psc-${substr(var.dashboard_grafana.name, 0, 76)}"
    private_connection_resource_id = azurerm_dashboard_grafana.this.id
    is_manual_connection           = false
    subresource_names              = ["grafana"]
  }

  private_dns_zone_group {
    name                 = "privatelink.grafana.azure.com"
    private_dns_zone_ids = var.dashboard_grafana_private_endpoint.private_dns_zone_group.private_dns_zone_ids
  }

  tags = merge(var.tags, var.dashboard_grafana_private_endpoint.tags)
}