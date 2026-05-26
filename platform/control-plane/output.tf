output "keda" {
  value = {
    monitor_workspace = {
      id                                  = azurerm_monitor_workspace.this.id
      query_endpoint                      = azurerm_monitor_workspace.this.query_endpoint
      default_data_collection_endpoint_id = azurerm_monitor_workspace.this.default_data_collection_endpoint_id
      default_data_collection_rule_id     = azurerm_monitor_workspace.this.default_data_collection_rule_id
    }

    monitor_workspace_private_endpoint = {
      id = azurerm_private_endpoint.monitor_workspace.id
    }

    dashboard_grafana = {
      id          = azurerm_dashboard_grafana.this.id
      endpoint    = azurerm_dashboard_grafana.this.endpoint
      identity    = azurerm_dashboard_grafana.this.identity
      outbound_ip = azurerm_dashboard_grafana.this.outbound_ip
    }

    dashboard_grafana_private_endpoint = {
      id = azurerm_private_endpoint.dashboard_grafana.id
    }
  }
}


