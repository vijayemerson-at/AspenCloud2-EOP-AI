variable "resource_group" {
  description = "Resource group"
  type = object({
    name = string
    id   = string
  })
}

variable "location" {
  description = "Location for the resources"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "managed_identity_prefix" {
  description = "Prefix for the managed identities"
  type        = string
  default     = "uai"
}

variable "k8s_control_plane_authorization_tenant_id" {
  description = "AKS control plane Cluster API authentication tenant"
  type        = string
}

variable "cluster_admin_microsoft_entra_group_object_ids" {
  description = "Microsoft Entra groups in the identified tenant that will be granted the highly privileged cluster-admin role. If Azure RBAC is used, then this group will get a role assignment to Azure RBAC, else it will be assigned directly to the cluster's admin group."
  type        = list(string)
}

variable "kubernetes_cluster" {
  type = object({
    name               = string
    kubernetes_version = optional(string)
    sku_tier           = optional(string, "Standard")
    dns_prefix         = optional(string)
    identity = optional(object({
      type         = optional(string, "UserAssigned")
      identity_ids = optional(list(string), [])
    }))
    node_resource_group = optional(string)
    # agent pool profile (system only)
    default_node_pool = object({
      name                         = string
      orchestrator_version         = string
      vm_size                      = string
      os_disk_size_gb              = optional(number, 80)
      os_disk_type                 = optional(string, "Ephemeral")
      os_sku                       = optional(string, "AzureLinux")
      max_pods                     = optional(number, 30)
      type                         = optional(string, "VirtualMachineScaleSets")
      node_public_ip_enabled       = optional(bool, false)
      host_encryption_enabled      = optional(bool, false)
      fips_enabled                 = optional(bool, false)
      auto_scaling_enabled         = optional(bool, true)
      node_count                   = optional(number, 3)
      min_count                    = optional(number, 3)
      max_count                    = optional(number, 4)
      vnet_subnet_id               = string
      node_labels                  = optional(map(string), {})
      only_critical_addons_enabled = optional(bool, true)
      upgrade_settings = optional(object({
        drain_timeout_in_minutes      = optional(number)
        node_soak_duration_in_minutes = optional(number)
        max_surge                     = optional(string, "33%")
      }))
      zones                       = optional(list(string), ["1", "2", "3"])
      temporary_name_for_rotation = optional(string, null)
    })
    # aad profile
    role_based_access_control_enabled = optional(bool, true)
    azure_active_directory_role_based_access_control = object({
      tenant_id              = optional(string)
      admin_group_object_ids = optional(list(string), [])
      azure_rbac_enabled     = optional(bool)
    })
    # network profile
    network_profile = optional(object({
      network_plugin      = optional(string, "azure")
      network_plugin_mode = optional(string, "overlay")
      network_policy      = optional(string, "azure")
      outbound_type       = optional(string, "loadBalancer") # deviation from AKS baseline
      load_balancer_sku   = optional(string, "standard")
      load_balancer_profile = optional(object({
        backend_pool_type         = optional(string, "NodeIPConfiguration")
        idle_timeout_in_minutes   = optional(number, 30)
        managed_outbound_ip_count = optional(number)
        outbound_ip_address_ids   = optional(set(string))
        outbound_ip_prefix_ids    = optional(set(string))
        outbound_ports_allocated  = optional(number, 0)
      }))
      # When network_plugin is set to azure - the pod_cidr field must not be set, unless specifying network_plugin_mode to overlay.
      pod_cidr = optional(string)
      # This range should not be used by any network element on or connected to this VNet. Service address CIDR must be smaller than /12. docker_bridge_cidr, dns_service_ip and service_cidr should all be empty or all should be set.
      service_cidr   = optional(string)
      dns_service_ip = optional(string)
    }))

    # auto scaler profile
    auto_scaler_profile = optional(object({
      balance_similar_node_groups                   = optional(bool, false)
      daemonset_eviction_for_empty_nodes_enabled    = optional(bool, false)
      daemonset_eviction_for_occupied_nodes_enabled = optional(bool, true)
      expander                                      = optional(string, "random")
      ignore_daemonsets_utilization_enabled         = optional(bool, false)
      max_graceful_termination_sec                  = optional(number, 600)
      max_node_provisioning_time                    = optional(string, "15m")
      max_unready_nodes                             = optional(number, 3)
      max_unready_percentage                        = optional(number, "45")
      new_pod_scale_up_delay                        = optional(string, "0s")
      scale_down_delay_after_add                    = optional(string, "10m")
      scale_down_delay_after_delete                 = optional(string, "10s")
      scale_down_delay_after_failure                = optional(string, "3m")
      scale_down_unneeded                           = optional(string, "10m")
      scale_down_unready                            = optional(string, "20m")
      scale_down_utilization_threshold              = optional(number, "0.5")
      scan_interval                                 = optional(string, "10s")
      empty_bulk_delete_max                         = optional(number, 10)
      skip_nodes_with_local_storage                 = optional(bool, true)
      skip_nodes_with_system_pods                   = optional(bool, true)
    }))

    # api server access profile
    private_cluster_enabled = optional(bool, false)
    api_server_access_profile = optional(object({
      authorized_ip_ranges = optional(list(string), [])
    }))

    # auto upgrade profile
    node_os_upgrade_channel   = optional(string, "NodeImage")
    automatic_upgrade_channel = optional(string)
    maintenance_window = optional(object({
      allowed = optional(object({
        day   = string
        hours = list(string)
      }))
      not_allowed = optional(object({
        start = string
        end   = string
      }))
    }))
    maintenance_window_auto_upgrade = optional(object({
      frequency    = string
      interval     = number
      duration     = number
      day_of_week  = optional(string)
      day_of_month = optional(string)
      week_index   = optional(string)
      start_time   = optional(string)
      utc_offset   = optional(string)
      start_date   = optional(string)
      not_allowed = optional(object({
        start = string
        end   = string
      }))
    }))
    maintenance_window_node_os = optional(object({
      frequency    = string
      interval     = number
      duration     = number
      day_of_week  = optional(string)
      day_of_month = optional(string)
      week_index   = optional(string)
      start_time   = optional(string)
      utc_offset   = optional(string)
      start_date   = optional(string)
      not_allowed = optional(object({
        start = string
        end   = string
      }))
    }))

    # upgrade override
    upgrade_override = optional(object({
      force_upgrade_enabled = optional(bool, false)
      effective_until       = optional(string, null)
    }))

    # azure monitor profile
    monitor_metrics = optional(object({
      annotations_allowed = optional(string)
      labels_allowed      = optional(string)
    }))

    # linux profile
    linux_profile = optional(object({
      admin_username = string
      ssh_key = object({
        key_data = string
      })
    }))

    # windows profile
    windows_profile = optional(object({
      admin_username = string
      admin_password = optional(string)
      license        = optional(string)
      gmsa = optional(object({
        dns_server  = string
        root_domain = string
      }))
    }))

    # storage profile
    storage_profile = optional(object({
      blob_driver_enabled         = optional(bool, false)
      disk_driver_enabled         = optional(bool, true)
      file_driver_enabled         = optional(bool, true)
      snapshot_controller_enabled = optional(bool, true)
    }))

    # workload autoscaler profile
    workload_autoscaler_profile = optional(object({
      keda_enabled                    = optional(bool, false)
      vertical_pod_autoscaler_enabled = optional(bool, false)
    }))

    local_account_disabled = optional(bool, true)

    # security profile
    workload_identity_enabled    = optional(bool, true)
    image_cleaner_enabled        = optional(bool, true)
    image_cleaner_interval_hours = optional(number, 120)
    microsoft_defender = optional(object({
      log_analytics_workspace_id = string
    }))

    # oidc issuer profile
    oidc_issuer_enabled = optional(bool, true)

    # addon profile
    http_application_routing_enabled = optional(bool, false)
    ingress_application_gateway = optional(object({
      gateway_id   = optional(string)
      gateway_name = optional(string)
      subnet_cidr  = optional(string)
      subnet_id    = optional(string)
    }))
    oms_agent = optional(object({
      log_analytics_workspace_id      = string
      msi_auth_for_monitoring_enabled = optional(bool)
    }))
    aci_connector_linux = optional(object({
      subnet_name = string
    }))
    azure_policy_enabled      = optional(bool, true)
    open_service_mesh_enabled = optional(bool, false)
    key_vault_secrets_provider = optional(object({
      secret_rotation_enabled  = optional(bool, false)
      secret_rotation_interval = optional(string, "2m")
    }))
    tags = optional(map(string), {})
  })
}