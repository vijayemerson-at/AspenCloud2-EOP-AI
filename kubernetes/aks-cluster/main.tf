data "azurerm_subscription" "current" {}

locals {
  is_using_azure_rbac_as_kubernetes_rbac = (data.azurerm_subscription.current.tenant_id == var.k8s_control_plane_authorization_tenant_id)
}

resource "azurerm_user_assigned_identity" "cluster_control_plane" {
  name                = "${substr(var.managed_identity_prefix, 0, 115)}-controlplane"
  location            = var.location
  resource_group_name = var.resource_group.name
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.kubernetes_cluster.name
  location            = var.location
  resource_group_name = var.resource_group.name

  kubernetes_version = var.kubernetes_cluster.kubernetes_version
  sku_tier           = "Standard"
  dns_prefix         = var.kubernetes_cluster.name # TODO what to put here? In biceps it's: uniqueString(subscription().subscriptionId, resourceGroup().id, clusterName)

  identity {
    type         = "UserAssigned" # SystemAssigned
    identity_ids = [azurerm_user_assigned_identity.cluster_control_plane.id]
  }

  node_resource_group = "${substr(var.resource_group.name, 0, 80)}-nodepools"

  # agent pool profile (system only)
  default_node_pool {
    name                 = var.kubernetes_cluster.default_node_pool.name
    orchestrator_version = var.kubernetes_cluster.default_node_pool.orchestrator_version
    vm_size              = var.kubernetes_cluster.default_node_pool.vm_size
    os_disk_size_gb      = var.kubernetes_cluster.default_node_pool.os_disk_size_gb
    os_disk_type         = var.kubernetes_cluster.default_node_pool.os_disk_type
    os_sku               = var.kubernetes_cluster.default_node_pool.os_sku
    max_pods             = var.kubernetes_cluster.default_node_pool.max_pods
    type                 = var.kubernetes_cluster.default_node_pool.type

    node_public_ip_enabled  = var.kubernetes_cluster.default_node_pool.node_public_ip_enabled
    host_encryption_enabled = var.kubernetes_cluster.default_node_pool.host_encryption_enabled
    fips_enabled            = var.kubernetes_cluster.default_node_pool.fips_enabled

    auto_scaling_enabled = var.kubernetes_cluster.default_node_pool.auto_scaling_enabled
    node_count           = var.kubernetes_cluster.default_node_pool.node_count
    min_count            = var.kubernetes_cluster.default_node_pool.min_count
    max_count            = var.kubernetes_cluster.default_node_pool.max_count

    vnet_subnet_id = var.kubernetes_cluster.default_node_pool.vnet_subnet_id

    node_labels                  = var.kubernetes_cluster.default_node_pool.node_labels
    only_critical_addons_enabled = var.kubernetes_cluster.default_node_pool.only_critical_addons_enabled

    dynamic "upgrade_settings" {
      for_each = var.kubernetes_cluster.default_node_pool.upgrade_settings[*]

      content {
        drain_timeout_in_minutes      = var.kubernetes_cluster.default_node_pool.upgrade_settings.drain_timeout_in_minutes
        node_soak_duration_in_minutes = var.kubernetes_cluster.default_node_pool.upgrade_settings.node_soak_duration_in_minutes
        max_surge                     = var.kubernetes_cluster.default_node_pool.upgrade_settings.max_surge
      }
    }

    zones                       = var.kubernetes_cluster.default_node_pool.zones
    temporary_name_for_rotation = var.kubernetes_cluster.default_node_pool.temporary_name_for_rotation # needed for node pool rotation after changing vm_size
  }
  role_based_access_control_enabled = var.kubernetes_cluster.role_based_access_control_enabled

  # aad profile
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.kubernetes_cluster.azure_active_directory_role_based_access_control[*]

    content {
      tenant_id              = var.k8s_control_plane_authorization_tenant_id
      admin_group_object_ids = local.is_using_azure_rbac_as_kubernetes_rbac ? var.cluster_admin_microsoft_entra_group_object_ids : []
      azure_rbac_enabled     = var.kubernetes_cluster.azure_active_directory_role_based_access_control.azure_rbac_enabled != null ? var.kubernetes_cluster.azure_active_directory_role_based_access_control.azure_rbac_enabled : local.is_using_azure_rbac_as_kubernetes_rbac
    }
  }

  # network profile
  dynamic "network_profile" {
    for_each = var.kubernetes_cluster.network_profile[*]

    content {
      network_plugin      = var.kubernetes_cluster.network_profile.network_plugin
      network_plugin_mode = var.kubernetes_cluster.network_profile.network_plugin_mode
      network_policy      = var.kubernetes_cluster.network_profile.network_policy
      # TODO document deviation of not using userDefinedRouting (we are not routing to the Firewall)
      # TODO replace with NSG outbound rules
      outbound_type     = var.kubernetes_cluster.network_profile.outbound_type
      load_balancer_sku = var.kubernetes_cluster.network_profile.load_balancer_sku

      dynamic "load_balancer_profile" {
        for_each = var.kubernetes_cluster.network_profile.load_balancer_profile[*]

        content {
          backend_pool_type         = var.kubernetes_cluster.network_profile.load_balancer_profile.backend_pool_type
          idle_timeout_in_minutes   = var.kubernetes_cluster.network_profile.load_balancer_profile.idle_timeout_in_minutes
          managed_outbound_ip_count = var.kubernetes_cluster.network_profile.load_balancer_profile.managed_outbound_ip_count
          outbound_ip_address_ids   = var.kubernetes_cluster.network_profile.load_balancer_profile.outbound_ip_address_ids
          outbound_ip_prefix_ids    = var.kubernetes_cluster.network_profile.load_balancer_profile.outbound_ip_prefix_ids
          outbound_ports_allocated  = var.kubernetes_cluster.network_profile.load_balancer_profile.outbound_ports_allocated
        }
      }
      pod_cidr       = var.kubernetes_cluster.network_profile.pod_cidr
      service_cidr   = var.kubernetes_cluster.network_profile.service_cidr
      dns_service_ip = var.kubernetes_cluster.network_profile.dns_service_ip
    }
  }

  # auto scaler profile
  dynamic "auto_scaler_profile" {
    for_each = var.kubernetes_cluster.auto_scaler_profile[*]

    content {
      balance_similar_node_groups      = var.kubernetes_cluster.auto_scaler_profile.balance_similar_node_groups
      expander                         = var.kubernetes_cluster.auto_scaler_profile.expander
      empty_bulk_delete_max            = var.kubernetes_cluster.auto_scaler_profile.empty_bulk_delete_max
      max_graceful_termination_sec     = var.kubernetes_cluster.auto_scaler_profile.max_graceful_termination_sec
      max_node_provisioning_time       = var.kubernetes_cluster.auto_scaler_profile.max_node_provisioning_time
      max_unready_nodes                = var.kubernetes_cluster.auto_scaler_profile.max_unready_nodes
      max_unready_percentage           = var.kubernetes_cluster.auto_scaler_profile.max_unready_percentage
      new_pod_scale_up_delay           = var.kubernetes_cluster.auto_scaler_profile.new_pod_scale_up_delay
      scale_down_delay_after_add       = var.kubernetes_cluster.auto_scaler_profile.scale_down_delay_after_add
      scale_down_delay_after_delete    = var.kubernetes_cluster.auto_scaler_profile.scale_down_delay_after_delete
      scale_down_delay_after_failure   = var.kubernetes_cluster.auto_scaler_profile.scale_down_delay_after_failure
      scale_down_unneeded              = var.kubernetes_cluster.auto_scaler_profile.scale_down_unneeded
      scale_down_unready               = var.kubernetes_cluster.auto_scaler_profile.scale_down_unready
      scale_down_utilization_threshold = var.kubernetes_cluster.auto_scaler_profile.scale_down_utilization_threshold
      scan_interval                    = var.kubernetes_cluster.auto_scaler_profile.scan_interval
      skip_nodes_with_local_storage    = var.kubernetes_cluster.auto_scaler_profile.skip_nodes_with_local_storage
      skip_nodes_with_system_pods      = var.kubernetes_cluster.auto_scaler_profile.skip_nodes_with_system_pods
    }
  }

  # api server access profile
  private_cluster_enabled = var.kubernetes_cluster.private_cluster_enabled
  dynamic "api_server_access_profile" {
    for_each = var.kubernetes_cluster.api_server_access_profile[*]

    content {
      authorized_ip_ranges = var.kubernetes_cluster.api_server_access_profile.authorized_ip_ranges
    }
  }

  # auto upgrade profile
  node_os_upgrade_channel   = var.kubernetes_cluster.node_os_upgrade_channel
  automatic_upgrade_channel = var.kubernetes_cluster.automatic_upgrade_channel

  dynamic "maintenance_window" {
    for_each = var.kubernetes_cluster.maintenance_window[*]

    content {
      dynamic "allowed" {
        for_each = maintenance_window.value.allowed[*]

        content {
          day   = allowed.value.day
          hours = allowed.value.hours
        }
      }

      dynamic "not_allowed" {
        for_each = maintenance_window.value.not_allowed[*]

        content {
          start = not_allowed.value.start
          end   = not_allowed.value.end
        }
      }
    }
  }

  dynamic "maintenance_window_auto_upgrade" {
    for_each = var.kubernetes_cluster.maintenance_window_auto_upgrade[*]

    content {
      frequency    = maintenance_window_auto_upgrade.value.frequency
      interval     = maintenance_window_auto_upgrade.value.interval
      duration     = maintenance_window_auto_upgrade.value.duration
      day_of_week  = maintenance_window_auto_upgrade.value.day_of_week
      day_of_month = maintenance_window_auto_upgrade.value.day_of_month
      week_index   = maintenance_window_auto_upgrade.value.week_index
      start_time   = maintenance_window_auto_upgrade.value.start_time
      utc_offset   = maintenance_window_auto_upgrade.value.utc_offset
      start_date   = maintenance_window_auto_upgrade.value.start_date

      dynamic "not_allowed" {
        for_each = maintenance_window_auto_upgrade.value.not_allowed[*]

        content {
          start = not_allowed.value.start
          end   = not_allowed.value.end
        }
      }
    }
  }

  dynamic "maintenance_window_node_os" {
    for_each = var.kubernetes_cluster.maintenance_window_node_os[*]

    content {
      frequency    = maintenance_window_node_os.value.frequency
      interval     = maintenance_window_node_os.value.interval
      duration     = maintenance_window_node_os.value.duration
      day_of_week  = maintenance_window_node_os.value.day_of_week
      day_of_month = maintenance_window_node_os.value.day_of_month
      week_index   = maintenance_window_node_os.value.week_index
      start_time   = maintenance_window_node_os.value.start_time
      utc_offset   = maintenance_window_node_os.value.utc_offset
      start_date   = maintenance_window_node_os.value.start_date

      dynamic "not_allowed" {
        for_each = maintenance_window_node_os.value.not_allowed[*]

        content {
          start = not_allowed.value.start
          end   = not_allowed.value.end
        }
      }
    }
  }

  # upgrade override
  dynamic "upgrade_override" {
    for_each = var.kubernetes_cluster.upgrade_override[*]

    content {
      force_upgrade_enabled = var.kubernetes_cluster.upgrade_override.force_upgrade_enabled
      effective_until       = var.kubernetes_cluster.upgrade_override.effective_until
    }
  }

  # azure monitor profile
  dynamic "monitor_metrics" {
    for_each = var.kubernetes_cluster.monitor_metrics[*]

    content {
      annotations_allowed = var.kubernetes_cluster.monitor_metrics.annotations_allowed
      labels_allowed      = var.kubernetes_cluster.monitor_metrics.labels_allowed
    }
  }

  # linux profile
  dynamic "linux_profile" {
    for_each = var.kubernetes_cluster.linux_profile[*]

    content {
      admin_username = var.kubernetes_cluster.linux_profile.admin_username
      ssh_key {
        key_data = var.kubernetes_cluster.linux_profile.ssh_key.key_data
      }
    }
  }

  # windows profile
  dynamic "windows_profile" {
    for_each = var.kubernetes_cluster.windows_profile[*]

    content {
      admin_username = var.kubernetes_cluster.windows_profile.admin_username
      admin_password = var.kubernetes_cluster.windows_profile.admin_password
      license        = var.kubernetes_cluster.windows_profile.license

      dynamic "gmsa" {
        for_each = var.kubernetes_cluster.windows_profile.gmsa[*]

        content {
          dns_server  = var.kubernetes_cluster.windows_profile.gmsa.dns_server
          root_domain = var.kubernetes_cluster.windows_profile.gmsa.root_domain
        }
      }
    }
  }

  # storage profile
  dynamic "storage_profile" {
    for_each = var.kubernetes_cluster.storage_profile[*]

    content {
      blob_driver_enabled         = var.kubernetes_cluster.storage_profile.blob_driver_enabled
      disk_driver_enabled         = var.kubernetes_cluster.storage_profile.disk_driver_enabled
      file_driver_enabled         = var.kubernetes_cluster.storage_profile.file_driver_enabled
      snapshot_controller_enabled = var.kubernetes_cluster.storage_profile.snapshot_controller_enabled
    }
  }

  # workload autoscaler profile
  dynamic "workload_autoscaler_profile" {
    for_each = var.kubernetes_cluster.workload_autoscaler_profile[*]

    content {
      keda_enabled                    = var.kubernetes_cluster.workload_autoscaler_profile.keda_enabled
      vertical_pod_autoscaler_enabled = var.kubernetes_cluster.workload_autoscaler_profile.vertical_pod_autoscaler_enabled
    }
  }

  local_account_disabled = var.kubernetes_cluster.local_account_disabled

  # security profile
  workload_identity_enabled    = true
  image_cleaner_enabled        = true
  image_cleaner_interval_hours = 120
  dynamic "microsoft_defender" {
    for_each = var.kubernetes_cluster.microsoft_defender[*]

    content {
      log_analytics_workspace_id = var.kubernetes_cluster.microsoft_defender.log_analytics_workspace_id
    }
  }

  # oidc issuer profile
  oidc_issuer_enabled = var.kubernetes_cluster.oidc_issuer_enabled

  # addon profile
  http_application_routing_enabled = var.kubernetes_cluster.http_application_routing_enabled
  dynamic "ingress_application_gateway" {
    for_each = var.kubernetes_cluster.ingress_application_gateway[*]

    content {
      gateway_id   = var.kubernetes_cluster.ingress_application_gateway.gateway_id
      gateway_name = var.kubernetes_cluster.ingress_application_gateway.gateway_name
      subnet_cidr  = var.kubernetes_cluster.ingress_application_gateway.subnet_cidr
      subnet_id    = var.kubernetes_cluster.ingress_application_gateway.subnet_id
    }
  }
  dynamic "oms_agent" {
    for_each = var.kubernetes_cluster.oms_agent[*]

    content {
      log_analytics_workspace_id      = var.kubernetes_cluster.oms_agent.log_analytics_workspace_id
      msi_auth_for_monitoring_enabled = var.kubernetes_cluster.oms_agent.msi_auth_for_monitoring_enabled
    }
  }
  dynamic "aci_connector_linux" {
    for_each = var.kubernetes_cluster.aci_connector_linux[*]

    content {
      subnet_name = var.kubernetes_cluster.aci_connector_linux.subnet_name
    }
  }
  azure_policy_enabled      = var.kubernetes_cluster.azure_policy_enabled
  open_service_mesh_enabled = var.kubernetes_cluster.open_service_mesh_enabled
  dynamic "key_vault_secrets_provider" {
    for_each = var.kubernetes_cluster.key_vault_secrets_provider[*]

    content {
      secret_rotation_enabled  = var.kubernetes_cluster.key_vault_secrets_provider.secret_rotation_enabled
      secret_rotation_interval = var.kubernetes_cluster.key_vault_secrets_provider.secret_rotation_interval
    }
  }

  lifecycle {
    ignore_changes = [
      tags,
      default_node_pool[0].tags,
      default_node_pool[0].node_count,
    ]
  }

  tags = merge(var.tags, var.kubernetes_cluster.tags)

  depends_on = [
    # sci # Solution Container Insights

    azurerm_role_assignment.snet_cluster_nodes_mi_cluster_control_plane_network_contributor,

    // Policies that we need in place before the cluster is deployed or pods are deployed to it.
    // They are not technically a dependency from the resource provider perspective,
    // but logically they need to be in place before workloads are, so forcing that here. This also
    // ensures that the policies are applied to the cluster at bootstrapping time.
    # policies

    # dcr # Data Collection Rules

    # linked to ingress controller and / or kv
    # peKv
    # kvPodMiIngressControllerKeyVaultReader_roleAssignment0
    # kvPodMiIngressControllerSecretsUserRole_roleAssignment
  ]
}

resource "azurerm_role_assignment" "snet_cluster_nodes_mi_cluster_control_plane_network_contributor" {
  scope                = var.kubernetes_cluster.default_node_pool.vnet_subnet_id
  principal_id         = azurerm_user_assigned_identity.cluster_control_plane.principal_id
  role_definition_name = "Network Contributor"
}

resource "azurerm_role_assignment" "rg_cluster_user_assigned_virtual_machine_contributor" {
  scope                = var.resource_group.id
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  role_definition_name = "Virtual Machine Contributor"

  depends_on = [azurerm_kubernetes_cluster.this]
}

resource "azurerm_role_assignment" "mc_admin_group_cluster_admin_role" {
  for_each = toset(var.cluster_admin_microsoft_entra_group_object_ids)

  scope                = azurerm_kubernetes_cluster.this.id
  principal_id         = each.value
  principal_type       = "Group"
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
}

resource "azurerm_role_assignment" "mc_admin_group_service_cluster_user_role" {
  for_each = toset(var.cluster_admin_microsoft_entra_group_object_ids)

  scope                = azurerm_kubernetes_cluster.this.id
  principal_id         = each.value
  principal_type       = "Group"
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
}