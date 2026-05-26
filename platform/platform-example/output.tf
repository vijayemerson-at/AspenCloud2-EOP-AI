output "kubernetes_cluster" {
  value = {
    name            = module.cluster.kubernetes_cluster.name
    fqdn            = module.cluster.kubernetes_cluster.fqdn
    oidc_issuer_url = module.cluster.kubernetes_cluster.oidc_issuer_url
    resource_group  = azurerm_resource_group.aks.name
  }
}

output "keda" {
  value = {
    monitor_workspace = {
      query_endpoint = module.control-plane.keda.monitor_workspace.query_endpoint
    }

    dashboard_grafana = {
      endpoint = module.control-plane.keda.dashboard_grafana.endpoint
    }
  }
}

output "system-services" {
  value = {
    key_vault_name      = module.system-services.key_vault_name
    key_vault_tenant_id = module.system-services.key_vault_tenant_id
    key_vault_identity = module.system-services.key_vault_identity != null ? {
      service_accounts        = module.system-services.key_vault_identity.service_accounts
      user_assigned_client_id = module.system-services.key_vault_identity.user_assigned_client_id
    } : null
  }
}

output "network" {
  value = {
    virtual_network = {
      id            = module.aks-spoke.virtual_network.id
      name          = module.aks-spoke.virtual_network.name
      address_space = module.aks-spoke.virtual_network.address_space
    },
    subnet_clusternodes = {
      id               = module.aks-spoke.subnet_clusternodes.id
      address_prefixes = module.aks-spoke.subnet_clusternodes.address_prefixes
    },
    subnet_applicationgateway = {
      id               = module.aks-spoke.subnet_applicationgateway.id
      address_prefixes = module.aks-spoke.subnet_applicationgateway.address_prefixes
    },
    subnet_aksilb = {
      id               = module.aks-spoke.subnet_aksilb.id
      address_prefixes = module.aks-spoke.subnet_aksilb.address_prefixes
    },
    subnet_privatelinkendpoints = {
      id               = module.aks-spoke.subnet_privatelinkendpoints.id
      address_prefixes = module.aks-spoke.subnet_privatelinkendpoints.address_prefixes
    },
    blob_private_dns_zone = {
      id = module.blob_private_dns.private_dns_zone.id
    }
    dfs_private_dns_zone = {
      id = module.dfs_private_dns.private_dns_zone.id
    }
    eventgrid_domain_private_dns_zone = {
      id = module.eventgrid_domain_private_dns.private_dns_zone.id
    }
    grafana_dashboard_private_dns_zone = {
      id = module.grafana_dashboard_private_dns.private_dns_zone.id
    }
    keyvault_private_dns_zone = {
      id = module.keyvault_private_dns.private_dns_zone.id
    }
    monitor_workspace_private_dns_zone = {
      id = module.monitor_workspace_private_dns.private_dns_zone.id
    }
    openai_private_dns_zone = {
      id = module.openai_private_dns.private_dns_zone.id
    }
    postgres_private_dns_zone = {
      id = module.postgres_private_dns.private_dns_zone.id
    }
    queue_private_dns_zone = {
      id = module.queue_private_dns.private_dns_zone.id
    }
    redis_cache_private_dns_zone = {
      id = module.redis_cache_private_dns.private_dns_zone.id
    }
    cognitive_services_private_dns_zone = {
      id = module.cognitive_services_private_dns.private_dns_zone.id
    }
  }
}
