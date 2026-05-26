locals {
  tags = merge({
    DomainId = var.domain_id
  }, var.tags)
  helm_repositories = {
    "platform" : { "type" = "oci", "url" = "oci://${var.aspentech_registry_url}/chartrepo", "username" = var.aspentech_registry_user, "password" = var.aspentech_registry_password }
  }
  container_image_repositories = {
    "platform" : { "host" = var.aspentech_registry_url, "username" = var.aspentech_registry_user, "password" = var.aspentech_registry_password, "email" = var.aspentech_registry_email }
  }
  oidc_issuer   = "https://login.microsoftonline.com/${var.oidc_tenant_id}"
  oidc_metadata = "https://login.microsoftonline.com/${var.oidc_tenant_id}/v2.0/.well-known/openid-configuration"
}

data "azurerm_subscription" "current" {}


#### Used in Control Plane
resource "random_string" "alpha" {
  length  = 60
  special = false
  upper   = false
  numeric = false
}

#### Used everywhere
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
  suffix  = [var.domain_id]
}

# Networking
resource "azurerm_resource_group" "network" {
  location = var.location
  name     = "${substr(module.naming.resource_group.name_unique, 0, 82)}-network"
  tags     = local.tags
}

module "aks-spoke" {
  source              = "../../network/aks-spoke"
  location            = var.location
  resource_group_name = azurerm_resource_group.network.name
  domain_id           = var.domain_id

  virtual_network = {
    address_space = var.virtual_network_address_space
  }

  subnet_privatelinkendpoints = {
    address_prefixes = var.subnet_privatelinkendpoints_address_prefixes
  }

  subnet_aksilb = {
    address_prefixes = var.subnet_aksilb_address_prefixes
  }

  subnet_applicationgateway = {
    address_prefixes = var.subnet_applicationgateway_address_prefixes
  }

  subnet_clusternodes = {
    address_prefixes = var.subnet_clusternodes_address_prefixes
  }

  tags = local.tags

  depends_on = [azurerm_resource_group.network]
}

resource "azurerm_resource_group" "aks" {
  location = var.location
  name     = "${substr(module.naming.resource_group.name_unique, 0, 86)}-aks"

  tags = local.tags
}

## Add private DNS here as needed, sorted in alphabetical order for easier management
module "blob_private_dns" {
  source = "../../network/blob-private-dns-zone"

  resource_group_name = azurerm_resource_group.network.name
  private_dns_zone_virtual_network_link = {
    virtual_network_id = module.aks-spoke.virtual_network.id
  }

  tags = local.tags

  depends_on = [azurerm_resource_group.network]
}

module "cognitive_services_private_dns" {
  source = "../../network/cognitive-services-private-dns-zone"

  resource_group_name = azurerm_resource_group.network.name
  private_dns_zone_virtual_network_link = {
    virtual_network_id = module.aks-spoke.virtual_network.id
  }

  tags = local.tags

  depends_on = [azurerm_resource_group.network]
}

module "dfs_private_dns" {
  source = "../../network/dfs-private-dns-zone"

  resource_group_name = azurerm_resource_group.network.name
  private_dns_zone_virtual_network_link = {
    virtual_network_id = module.aks-spoke.virtual_network.id
  }

  tags = local.tags

  depends_on = [azurerm_resource_group.network]
}

module "eventgrid_domain_private_dns" {
  source = "../../network/eventgrid-domain-private-dns-zone"

  resource_group_name = azurerm_resource_group.network.name
  private_dns_zone_virtual_network_link = {
    virtual_network_id = module.aks-spoke.virtual_network.id
  }

  tags = local.tags

  depends_on = [azurerm_resource_group.network]
}

module "grafana_dashboard_private_dns" {
  source = "../../network/grafana-dashboard-private-dns-zone"

  resource_group_name = azurerm_resource_group.network.name
  private_dns_zone_virtual_network_link = {
    virtual_network_id = module.aks-spoke.virtual_network.id
  }

  tags = local.tags

  depends_on = [azurerm_resource_group.network]
}

module "keyvault_private_dns" {
  source = "../../network/keyvault-private-dns-zone"

  resource_group_name = azurerm_resource_group.network.name
  private_dns_zone_virtual_network_link = {
    virtual_network_id = module.aks-spoke.virtual_network.id
  }

  tags = local.tags

  depends_on = [azurerm_resource_group.network]
}

module "monitor_workspace_private_dns" {
  source = "../../network/monitor-workspace-private-dns-zone"

  resource_group_name = azurerm_resource_group.network.name
  location            = var.location
  private_dns_zone_virtual_network_link = {
    virtual_network_id = module.aks-spoke.virtual_network.id
  }

  tags = local.tags

  depends_on = [azurerm_resource_group.network]
}

module "openai_private_dns" {
  source = "../../network/openai-private-dns-zone"

  resource_group_name = azurerm_resource_group.network.name
  private_dns_zone_virtual_network_link = {
    virtual_network_id = module.aks-spoke.virtual_network.id
  }

  tags = local.tags

  depends_on = [azurerm_resource_group.network]
}

module "postgres_private_dns" {
  source = "../../network/postgres-private-dns-zone"

  resource_group_name = azurerm_resource_group.network.name
  private_dns_zone_virtual_network_link = {
    virtual_network_id = module.aks-spoke.virtual_network.id
  }

  tags = local.tags

  depends_on = [azurerm_resource_group.network]
}

module "queue_private_dns" {
  source = "../../network/queue-private-dns-zone"

  resource_group_name = azurerm_resource_group.network.name
  private_dns_zone_virtual_network_link = {
    virtual_network_id = module.aks-spoke.virtual_network.id
  }

  tags = local.tags

  depends_on = [azurerm_resource_group.network]
}

module "redis_cache_private_dns" {
  source = "../../network/redis-cache-private-dns-zone"

  resource_group_name = azurerm_resource_group.network.name
  private_dns_zone_virtual_network_link = {
    virtual_network_id = module.aks-spoke.virtual_network.id
  }

  tags = local.tags

  depends_on = [azurerm_resource_group.network]
}

# Kubernetes
module "cluster" {
  source = "../../kubernetes/aks-cluster"

  location = var.location
  resource_group = {
    id   = azurerm_resource_group.aks.id
    name = azurerm_resource_group.aks.name
  }

  k8s_control_plane_authorization_tenant_id      = data.azurerm_subscription.current.tenant_id
  cluster_admin_microsoft_entra_group_object_ids = var.cluster_admin_microsoft_entra_group_object_ids
  managed_identity_prefix                        = module.naming.user_assigned_identity.name

  kubernetes_cluster = {
    name               = module.naming.kubernetes_cluster.name
    kubernetes_version = var.cluster_kubernetes_version
    dns_prefix         = module.naming.kubernetes_cluster.name
    # TODO what to put here? In biceps it's: uniqueString(subscription().subscriptionId, resourceGroup().id, clusterName)
    default_node_pool = {
      name                 = "npsystem"
      orchestrator_version = var.cluster_orchestrator_version
      vm_size              = "Standard_D4ds_v5"
      os_disk_size_gb      = 150
      os_sku               = "AzureLinux"
      max_pods             = 30
      node_count           = 3
      min_count            = 3
      max_count            = 4
      vnet_subnet_id       = module.aks-spoke.subnet_clusternodes.id
      node_labels = {
        "node.aspencloud.ai/nodepool" = "system"
      }
      upgrade_settings = {
        max_surge = "33%"
      }
      zones = ["1", "2", "3"]
    }
    azure_active_directory_role_based_access_control = {
      tenant_id          = var.cluster_control_plane_authorization_tenant_id != null ? var.cluster_control_plane_authorization_tenant_id : data.azurerm_subscription.current.tenant_id
      azure_rbac_enabled = true
    }
    network_profile = {
      network_policy        = "calico"
      load_balancer_profile = null
      pod_cidr              = "192.168.0.0/16"
      service_cidr          = "172.16.0.0/16"
      dns_service_ip        = "172.16.0.10"
    }
    auto_scaler_profile = {
      max_unready_nodes                = "3"
      new_pod_scale_up_delay           = "0s"
      scale_down_delay_after_delete    = "20s"
      scale_down_utilization_threshold = "0.5"
    }
    private_cluster_enabled = false
    api_server_access_profile = {
      authorized_ip_ranges = var.cluster_api_server_authorized_ip_ranges
    }
    monitor_metrics = {
      annotations_allowed = null
      labels_allowed      = null
    }
    # linux_profile { # add if login into a linux node is needed
    #   admin_username = var.cluster_system_nodepool_linux_default_username
    #   ssh_key {
    #     key_data = var.cluster_system_nodepool_linux_ssh_public_key
    #   }
    # }
    # windows_profile { # add if login into a windows node is needed
    #   admin_password = var.cluster_system_nodepool_windows_default_password
    #   admin_username = var.cluster_system_nodepool_windows_default_username
    # }
    storage_profile = {
      blob_driver_enabled         = true # Needed for Blob Fuse Premium
      disk_driver_enabled         = true # Needed for PVCs
      file_driver_enabled         = true # Needed for Azure Files CSI
      snapshot_controller_enabled = false
    }
    workload_autoscaler_profile = {
      keda_enabled = false
    }
    local_account_disabled = var.cluster_local_account_disabled
    # dynamic "microsoft_defender" { # TODO: depends on log-analytics
    #   for_each = var.log_aggregation_mode == "azure-log-analytics" ? [true] : []
    #
    #   content {
    #     log_analytics_workspace_id = local.effective_log_analytics_workspace_id
    #   }
    # }
    oidc_issuer_enabled = true
    # dynamic "oms_agent" { # TODO on log-analytics
    #   for_each = var.log_aggregation_mode == "azure-log-analytics" ? [true] : []
    #
    #   content {
    #     log_analytics_workspace_id = local.effective_log_analytics_workspace_id
    #   }
    # }
    azure_policy_enabled = true
    key_vault_secrets_provider = {
      secret_rotation_enabled = true
    }
    upgrade_override = {
      force_upgrade_enabled = false
      effective_until       = "2010-10-10T10:10:10Z"
    }
    node_os_upgrade_channel         = var.cluster_node_os_upgrade_channel
    automatic_upgrade_channel       = var.cluster_automatic_upgrade_channel
    maintenance_window              = var.cluster_maintenance_window
    maintenance_window_auto_upgrade = var.cluster_maintenance_window_auto_upgrade
    maintenance_window_node_os      = var.cluster_maintenance_window_node_os
    tags = {
      "InstanceName" = module.naming.kubernetes_cluster.name
    }
  }
  tags = local.tags
}

module "user_node_pool" {
  source = "../../kubernetes/aks-node-pool"

  cluster_node_pool = {
    name = "npuser01"
    mode = "User"

    vm_size = "Standard_D4ds_v5"
    zones   = [1, 2, 3]

    kubernetes_cluster_id = module.cluster.kubernetes_cluster.id
    orchestrator_version  = var.cluster_orchestrator_version

    vnet_subnet_id         = module.aks-spoke.subnet_clusternodes.id
    node_public_ip_enabled = false

    os_sku                      = "AzureLinux"
    os_type                     = "Linux"
    os_disk_size_gb             = 150
    os_disk_type                = "Ephemeral"
    max_pods                    = 35
    temporary_name_for_rotation = "tmpnpuser01"

    auto_scaling_enabled = true
    node_count           = 2
    min_count            = 2
    max_count            = 5
    priority             = "Regular"

    host_encryption_enabled = false
    fips_enabled            = false

    upgrade_settings = {
      max_surge = "33%"
    }

    node_labels = {
      "node.aspencloud.ai/nodepool" = "npuser01",
    }

    tags = {
      "InstanceName" = module.cluster.kubernetes_cluster.name
    }
  }

  tags = local.tags
}

# Infra Services used in Kubernetes
module "control-plane" {
  source = "../control-plane"

  location = var.location
  resource_group = {
    id   = azurerm_resource_group.aks.id
    name = azurerm_resource_group.aks.name
  }

  global = {
    container_image_repositories = local.container_image_repositories
  }
  managed_identity_prefix = module.naming.user_assigned_identity.name

  # fluxcd / gitops
  fluxcd = {}
  gitops = {
    organization_name = var.gitops_organisation_name
    repository_name   = module.cluster.kubernetes_cluster.name
    helm_repositories = local.helm_repositories
  }

  # keda
  monitor_workspace = {
    name = join("-", ["mw", lower(var.domain_id)])
  }
  monitor_workspace_private_endpoint = {
    subnet_id = module.aks-spoke.subnet_privatelinkendpoints.id
    private_dns_zone_group = {
      private_dns_zone_ids = [module.monitor_workspace_private_dns.private_dns_zone.id]
    }
  }
  dashboard_grafana = {
    name                  = substr(join("-", ["mg", "aks", var.domain_id, random_string.alpha.result]), 0, 23)
    grafana_major_version = 11
  }
  dashboard_grafana_private_endpoint = {
    subnet_id = module.aks-spoke.subnet_privatelinkendpoints.id
    private_dns_zone_group = {
      private_dns_zone_ids = [module.grafana_dashboard_private_dns.private_dns_zone.id]
    }
  }

  system_services = {
    oidc_issuer                                = local.oidc_issuer
    oidc_metadata                              = local.oidc_metadata
    cluster_external_dns_zone_name             = var.cluster_external_dns_zone_name
    key_vault_name                             = module.system-services.key_vault_name
    key_vault_tenant_id                        = module.system-services.key_vault_tenant_id
    key_vault_identity_user_assigned_client_id = module.system-services.key_vault_identity.user_assigned_client_id
    software_license_manager_server_url        = var.software_license_manager_server_url
    software_license_manager_buckets           = var.software_license_manager_buckets
  }

  kubernetes_cluster = {
    id                     = module.cluster.kubernetes_cluster.id
    name                   = module.cluster.kubernetes_cluster.name
    oidc_issuer_url        = module.cluster.kubernetes_cluster.oidc_issuer_url
    host                   = module.cluster.kubernetes_cluster.host
    cluster_ca_certificate = module.cluster.kubernetes_cluster.cluster_ca_certificate
    aad_sp_client_id       = var.aks_aad_sp_client_id
    aad_sp_client_secret   = var.aks_aad_sp_client_secret
    aad_sp_tenant_id       = var.aks_aad_sp_tenant_id

    node_os_upgrade_channel         = var.cluster_node_os_upgrade_channel
    automatic_upgrade_channel       = var.cluster_automatic_upgrade_channel
    maintenance_window              = var.cluster_maintenance_window
    maintenance_window_auto_upgrade = var.cluster_maintenance_window_auto_upgrade
    maintenance_window_node_os      = var.cluster_maintenance_window_node_os
  }

  # log_aggregation_mode = "azure-log-analytics" # TODO: when we have log analytics
  tags = local.tags
}
