data "azurerm_client_config" "current" {
}

locals {
  cognitive_services_enabled = true
  storage_account_enabled    = true
  eventgrid_enabled          = true
  pg_enabled                 = true
  redis_managed_enabled      = true
  keyvault_enabled           = true
  appinsights_enabled        = var.appinsights_enabled
  service_account_namespace  = "asi" # hardcoded value shared with the product chart
  service_account_name       = "asi" # hardcoded value shared with the product chart

  tags = merge(var.tags, {
    DomainId    = var.domain_id
    ProductName = var.product_name
  })
}

#### ASI layer
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
  suffix  = [var.product_name, var.domain_id]
}

resource "azurerm_resource_group" "app" {
  location = var.location
  name     = module.naming.resource_group.name_unique

  tags = local.tags
}

# Cognitive Services (OpenAI)
module "openai" {
  count               = local.cognitive_services_enabled ? 1 : 0
  source              = "../../cognitive-services/private-cognitive-services"
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name

  cognitive_account = {
    name                  = "${substr(module.naming.cognitive_account.name, 0, 57)}-openai"
    kind                  = "OpenAI"
    sku_name              = "S0"
    custom_subdomain_name = "${substr(module.naming.cognitive_account.name, 0, 57)}-openai"
    network_acls_default_action = {
      default_action = "Allow"
    }
  }
  cognitive_deployments = [
    // gpt-5-mini or gpt-5.3-codex
    {
      name = var.openai_inference_model
      model = {
        format = "OpenAI"
        name   = var.openai_inference_model
        # versions are hardcoded for now as they are tied to specific model names
        version = var.openai_inference_model == "gpt-5.3-codex" ? "2026-02-24" : "2025-08-07"
      }
      sku = {
        name     = "GlobalStandard"
        capacity = var.openai_inference_model_capacity
      }
      rai_policy_name        = "Microsoft.DefaultV2"
      version_upgrade_option = "OnceCurrentVersionExpired"
    },
    // text-embedding-3-small
    {
      name = var.openai_embeddings_model
      model = {
        format  = "OpenAI"
        name    = var.openai_embeddings_model
        version = "1"
      }
      sku = {
        name     = "GlobalStandard"
        capacity = 120
      }
      rai_policy_name        = "Microsoft.DefaultV2"
      version_upgrade_option = "OnceCurrentVersionExpired"
    }
  ]
  private_endpoint = {
    subnet_id = var.subnet_privatelinkendpoints.id
    private_dns_zone_group = {
      private_dns_zone_ids = [var.openai_private_dns_zone.id]
    }
  }
  tags = local.tags
}

# Cognitive Services (Speech)
module "speech" {
  count               = local.cognitive_services_enabled ? 1 : 0
  source              = "../../cognitive-services/private-cognitive-services"
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name

  cognitive_account = {
    name                  = "${substr(module.naming.cognitive_account.name, 0, 57)}-speech"
    kind                  = "SpeechServices"
    sku_name              = var.speech_services_sku
    custom_subdomain_name = "${substr(module.naming.cognitive_account.name, 0, 57)}-speech"
    network_acls_default_action = {
      default_action = "Allow"
    }
  }
  private_endpoint = {
    subnet_id = var.subnet_privatelinkendpoints.id
    private_dns_zone_group = {
      private_dns_zone_ids = [var.cognitive_services_private_dns_zone.id]
    }
  }
  tags = local.tags
}

# Storage Account
module "storage" {
  count  = local.storage_account_enabled ? 1 : 0
  source = "../../storage/private-storage-account"

  location            = var.location
  resource_group_name = azurerm_resource_group.app.name
  storage_account = {
    name = replace(module.naming.storage_account.name_unique, "-", "")
    blob_properties = {
      cors_rule = {
        allowed_headers    = ["*"]
        allowed_methods    = ["GET", "HEAD", "OPTIONS", "PUT"]
        allowed_origins    = [var.instance_domain_url]
        exposed_headers    = ["*"]
        max_age_in_seconds = 333333
      }
    }
    queue_properties = {}
    network_rules = {
      default_action = "Allow"
    }
  }
  private_endpoints = [
    {
      subnet_id = var.subnet_privatelinkendpoints.id
      private_service_connection = {
        subresource_names = ["queue"]
      }
      private_dns_zone_group = {
        name                 = "queue"
        private_dns_zone_ids = [var.queue_private_dns_zone.id]
      }
    },
    {
      subnet_id = var.subnet_privatelinkendpoints.id
      private_service_connection = {
        subresource_names = ["blob"]
      }
      private_dns_zone_group = {
        name                 = "blob"
        private_dns_zone_ids = [var.blob_private_dns_zone.id]
      }
    }
  ]
  storage_containers = [{ name = "upload" }, { name = "download" }, { name = "openvds" }]
  storage_shares     = [{ name = "resqmlvolume", quota = 50 }, { name = "coredumps", quota = 50 }]
  tags               = local.tags
}

# Log Analytics Workspace for Application Insights
resource "azurerm_log_analytics_workspace" "this" {
  count = local.appinsights_enabled ? 1 : 0

  name                       = module.naming.log_analytics_workspace.name_unique
  location                   = var.location
  resource_group_name        = azurerm_resource_group.app.name
  sku                        = "PerGB2018"
  retention_in_days          = 30
  internet_ingestion_enabled = false
  internet_query_enabled     = false

  tags = local.tags
}

# Application Insights
resource "azurerm_application_insights" "this" {
  count = local.appinsights_enabled ? 1 : 0

  name                = module.naming.application_insights.name_unique
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name
  workspace_id        = azurerm_log_analytics_workspace.this[0].id
  application_type    = "web"

  tags = local.tags
}

resource "azurerm_role_assignment" "this" {
  scope                = azurerm_resource_group.app.id
  role_definition_name = "Contributor"
  principal_id         = var.asi_sp_object_id
}

resource "azurerm_role_assignment" "kv" {
  scope                = module.kv[0].key_vault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.asi_sp_object_id
}

# EventGrid
module "eg" {
  count  = local.eventgrid_enabled ? 1 : 0
  source = "../../messaging/private-eventgrid-domain"

  location            = var.location
  resource_group_name = azurerm_resource_group.app.name

  eventgrid_domain = {
    name = module.naming.eventgrid_domain.name
    identity = {
      type = "SystemAssigned"
    }
    input_schema                              = "EventGridSchema"
    auto_create_topic_with_first_subscription = true
    public_network_access_enabled             = true
  }

  private_endpoint = {
    subnet_id = var.subnet_privatelinkendpoints.id
    private_dns_zone_group = {
      private_dns_zone_ids = [var.eventgrid_domain_private_dns_zone.id]
    }
  }

  tags = local.tags
}

resource "time_sleep" "wait_for_eg_role_assignment" {
  count = local.eventgrid_enabled ? 1 : 0

  create_duration = "30s"

  depends_on = [module.eg[0]]
}

# Azure Managed Redis (Enterprise tier) - Primary Redis instance
module "redis_managed" {
  count  = local.redis_managed_enabled ? 1 : 0
  source = "../../database/private-redis-managed"

  location            = var.location
  resource_group_name = azurerm_resource_group.app.name
  redis = {
    name                = "${module.naming.redis_cache.name_unique}-managed"
    sku_name            = "Balanced_B1" # Single-shard balanced tier (1GB)
    clustering_policy   = "NoCluster"   # Non-clustered mode (standalone)
    redis_configuration = {}
    default_database = {
      access_keys_authentication_enabled = true
    }
  }
  private_endpoint = {
    subnet_id = var.subnet_privatelinkendpoints.id
    private_dns_zone_group = {
      private_dns_zone_ids = [var.redis_managed_private_dns_zone.id]
    }
  }
  tags = local.tags
}

# Database PostgreSQL
resource "random_password" "pg_admin" {
  count = local.pg_enabled ? 1 : 0

  length      = 16
  min_upper   = 4
  min_lower   = 2
  min_numeric = 4
  special     = false
}

module "flexible-postgresql" {
  count  = local.pg_enabled ? 1 : 0
  source = "../../database/private-postgres"

  location            = var.location
  resource_group_name = azurerm_resource_group.app.name

  postgresql_flexible_server = {
    name                   = module.naming.postgresql_server.name_unique
    administrator_login    = "postgresqlusername"
    administrator_password = random_password.pg_admin[0].result
    authentication = {
      active_directory_auth_enabled = false
      password_auth_enabled         = true
    }
    backup_retention_days = 7
    create_mode           = "Default"
    sku_name              = "GP_Standard_D4s_v3"
    storage_mb            = 524288
    storage_tier          = "P20"
    version               = "16"
    # This availability zone is required to match the one used 
    # by the AKS cluster data node pool: see  asi.tf 
    # module: asi_data_node_pool_az1, node pool: asidata-az1
    zone = "1"
  }
  private_endpoint = {
    subnet_id = var.subnet_privatelinkendpoints.id
    private_service_connection = {
      subresource_names = ["postgresqlServer"]
    }
    private_dns_zone_group = {
      name                 = "postgres"
      private_dns_zone_ids = [var.postgres_private_dns_zone.id]
    }
  }
  #Networking
  allow_azure_services_ips = false
  allow_all_ips            = false
  allowed_cidrs            = { for idx, cidr in var.postgres_allowed_cidrs : "Rule_${idx}" => cidr }
  #Override some server configurations
  server_configurations = {
    "azure.extensions"            = "pg_buffercache,pg_stat_statements,uuid-ossp"
    "log_autovacuum_min_duration" = "-1"
    "log_error_verbosity"         = "VERBOSE"
    "log_lock_waits"              = "ON"
    "password_encryption"         = "md5"
  }
  active_directory_administrators = var.pg_admins

  tags = local.tags
}

# Key Vault
## Identity used to access Key Vault from the AKS cluster
resource "azurerm_user_assigned_identity" "this" {
  count = local.keyvault_enabled ? 1 : 0

  location            = var.location
  name                = "${substr(module.naming.user_assigned_identity.name, 0, 125)}-kv"
  resource_group_name = azurerm_resource_group.app.name

  tags = local.tags
}

resource "azurerm_federated_identity_credential" "this" {
  count = local.keyvault_enabled ? 1 : 0

  name                = "aks-identity"
  resource_group_name = azurerm_resource_group.app.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer
  parent_id           = azurerm_user_assigned_identity.this[0].id
  subject             = "system:serviceaccount:${local.service_account_namespace}:${local.service_account_name}"

  depends_on = [azurerm_user_assigned_identity.this[0]]
}

module "kv" {
  count  = local.keyvault_enabled ? 1 : 0
  source = "../../secret-store/private-key-vault"

  location            = var.location
  resource_group_name = azurerm_resource_group.app.name
  key_vault = {
    name     = module.naming.key_vault.name_unique
    sku_name = "standard"
    network_acls = {
      ip_rules = var.keyvault_allowed_cidrs
    }
  }
  private_endpoint = {
    subnet_id = var.subnet_privatelinkendpoints.id
    private_dns_zone_group = {
      private_dns_zone_ids = [var.keyvault_private_dns_zone.id]
    }
  }

  # Requires Microsoft.Authorization/roleAssignments/write
  admin_user_object_ids = var.keyvault_admin_user_object_ids
  secrets_reader_object_ids = concat(var.keyvault_secrets_reader_object_ids, [
    azurerm_user_assigned_identity.this[0].principal_id
  ])

  tags = local.tags

  depends_on = [azurerm_resource_group.app, azurerm_user_assigned_identity.this[0]]
}

resource "time_sleep" "wait_for_kv_role_assignment" {
  count = local.keyvault_enabled ? 1 : 0

  create_duration = "30s"
  depends_on      = [module.kv[0]]
}

resource "azurerm_key_vault_secret" "tenantId" {
  count = local.keyvault_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "tenantId"
  value        = data.azurerm_client_config.current.tenant_id
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "subscriptionId" {
  count = local.keyvault_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "subscriptionId"
  value        = data.azurerm_client_config.current.subscription_id
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

# OIDC
resource "azurerm_key_vault_secret" "oidcClientId" {
  count = local.keyvault_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "oidcClientId"
  value        = var.oidc_idp_client_id
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "oidcClientSecret" {
  count = local.keyvault_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "oidcClientSecret"
  value        = var.oidc_idp_client_secret
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "oidcTenantId" {
  count = local.keyvault_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "oidcTenantId"
  value        = var.oidc_tenant_id
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

# Storage account
resource "azurerm_key_vault_secret" "storageAccountResourceGroup" {
  count = local.keyvault_enabled && local.storage_account_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "storageAccountResourceGroup"
  value        = azurerm_resource_group.app.name
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "storageAccountName" {
  count = local.keyvault_enabled && local.storage_account_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "storageAccountName"
  value        = module.storage[0].storage_account.name
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "storageAccountPrimaryAccessKey" {
  count = local.keyvault_enabled && local.storage_account_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "storageAccountPrimaryAccessKey"
  value        = module.storage[0].storage_account.primary_access_key
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "storageAccountPrimaryConnectionString" {
  count = local.keyvault_enabled && local.storage_account_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "storageAccountPrimaryConnectionString"
  value        = module.storage[0].storage_account.primary_connection_string
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "storageAccountSecondaryAccessKey" {
  count = local.keyvault_enabled && local.storage_account_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "storageAccountSecondaryAccessKey"
  value        = module.storage[0].storage_account.secondary_access_key
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "storageAccountSecondaryConnectionString" {
  count = local.keyvault_enabled && local.storage_account_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "storageAccountSecondaryConnectionString"
  value        = module.storage[0].storage_account.secondary_connection_string
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "storageAccountPrimaryBlobConnectionString" {
  count = local.keyvault_enabled && local.storage_account_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "storageAccountPrimaryBlobConnectionString"
  value        = module.storage[0].storage_account.primary_blob_connection_string
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "storageAccountSecondaryBlobConnectionString" {
  count = local.keyvault_enabled && local.storage_account_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "storageAccountSecondaryBlobConnectionString"
  value        = module.storage[0].storage_account.secondary_blob_connection_string
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

# EventGrid
resource "azurerm_key_vault_secret" "eventGridResourceGroup" {
  count = local.keyvault_enabled && local.eventgrid_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "eventGridResourceGroup"
  value        = azurerm_resource_group.app.name
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "eventGridClientId" {
  count = local.keyvault_enabled && local.eventgrid_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "eventGridClientId"
  value        = var.asi_sp_client_id
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "eventGridApplicationSecret" {
  count = local.keyvault_enabled && local.eventgrid_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "eventGridApplicationSecret"
  value        = var.asi_sp_client_secret
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "eventGridDomainName" {
  count = local.keyvault_enabled && local.eventgrid_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "eventGridDomainName"
  value        = module.eg[0].eventgrid_domain.name
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0], time_sleep.wait_for_eg_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "eventGridDomainLocation" {
  count = local.keyvault_enabled && local.eventgrid_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "eventGridDomainLocation"
  value        = var.location
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0], time_sleep.wait_for_eg_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "eventGridDomainEndpoint" {
  count = local.keyvault_enabled && local.eventgrid_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "eventGridDomainEndpoint"
  value        = module.eg[0].eventgrid_domain.endpoint
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0], time_sleep.wait_for_eg_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "eventGridDomainPrimaryAccessKey" {
  count = local.keyvault_enabled && local.eventgrid_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "eventGridDomainPrimaryAccessKey"
  value        = module.eg[0].eventgrid_domain.primary_access_key
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0], time_sleep.wait_for_eg_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "eventGridDomainSecondaryAccessKey" {
  count = local.keyvault_enabled && local.eventgrid_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "eventGridDomainSecondaryAccessKey"
  value        = module.eg[0].eventgrid_domain.secondary_access_key
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0], time_sleep.wait_for_eg_role_assignment[0]]
}

# Redis Cache - Primary connection string (uses Managed Redis)
resource "azurerm_key_vault_secret" "redisCachePrimaryConnectionString" {
  count = local.keyvault_enabled && local.redis_managed_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "redisCachePrimaryConnectionString"
  value        = "${module.redis_managed[0].redis.hostname}:${module.redis_managed[0].redis.port},password=${module.redis_managed[0].redis.primary_key},ssl=True,abortConnect=False"
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

# PostgreSQL
resource "azurerm_key_vault_secret" "postgresServerFqdn" {
  count = local.keyvault_enabled && local.pg_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "postgresServerFqdn"
  value        = module.flexible-postgresql[0].postgresql_flexible_server_fqdn
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "postgresServerName" {
  count = local.keyvault_enabled && local.pg_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "postgresServerName"
  value        = module.flexible-postgresql[0].postgresql_flexible_server_name
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "postgresServerPort" {
  count = local.keyvault_enabled && local.pg_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "postgresServerPort"
  value        = 5432
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "postgresServerDbNames" {
  count = local.keyvault_enabled && local.pg_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "postgresServerDbNames"
  value        = module.flexible-postgresql[0].postgresql_flexible_server_database_names
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "postgresServerAdminUsername" {
  count = local.keyvault_enabled && local.pg_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "postgresServerAdminUsername"
  value        = module.flexible-postgresql[0].postgresql_flexible_server_admin_login
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "postgresServerAdminPassword" {
  count = local.keyvault_enabled && local.pg_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "postgresServerAdminPassword"
  value        = module.flexible-postgresql[0].postgresql_flexible_server_admin_password
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}


# Requirements from OSDU open-etp server
resource "azurerm_key_vault_secret" "asiKeyVaultUrl" {
  count = local.keyvault_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "asiKeyVaultUrl"
  value        = "https://${module.kv[0].key_vault.name}.vault.azure.net"

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}

resource "azurerm_key_vault_secret" "aad-client-id" {
  count = local.keyvault_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "aad-client-id"
  value        = "https://vault.azure.net"

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}

# partition 1
resource "azurerm_key_vault_secret" "openetp-p1-connectionString" {
  count = local.keyvault_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "openetp-p1-connectionString"
  value        = "host=${module.flexible-postgresql[0].postgresql_flexible_server_fqdn} port=5432 dbname=openetp-p1 user=${module.flexible-postgresql[0].postgresql_flexible_server_admin_login} password=${module.flexible-postgresql[0].postgresql_flexible_server_admin_password}"

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}

# partition 2
resource "azurerm_key_vault_secret" "openetp-p2-connectionString" {
  count = local.keyvault_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "openetp-p2-connectionString"
  value        = "host=${module.flexible-postgresql[0].postgresql_flexible_server_fqdn} port=5432 dbname=openetp-p2 user=${module.flexible-postgresql[0].postgresql_flexible_server_admin_login} password=${module.flexible-postgresql[0].postgresql_flexible_server_admin_password}"

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}

# Cognitive Services
# - OpenAI
resource "azurerm_key_vault_secret" "cogAccOpenAiInstanceName" {
  count = local.keyvault_enabled && local.cognitive_services_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "cogAccOpenAiInstanceName"
  value        = module.openai[0].cognitive_account.name

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}

resource "azurerm_key_vault_secret" "cogAccOpenAiEndpoint" {
  count = local.keyvault_enabled && local.cognitive_services_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "cogAccOpenAIEndpoint"
  value        = module.openai[0].cognitive_account.endpoint

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}

resource "azurerm_key_vault_secret" "cogAccOpenAiPrimaryAccessKey" {
  count = local.keyvault_enabled && local.cognitive_services_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "cogAccOpenAIPrimaryAccessKey"
  value        = module.openai[0].cognitive_account.primary_access_key

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}

resource "azurerm_key_vault_secret" "cogAccOpenAiSecondaryAccessKey" {
  count = local.keyvault_enabled && local.cognitive_services_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "cogAccOpenAISecondaryAccessKey"
  value        = module.openai[0].cognitive_account.secondary_access_key

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}

resource "azurerm_key_vault_secret" "cogAccOpenAiInferenceModel" {
  count = local.keyvault_enabled && local.cognitive_services_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "cogAccOpenAiInferenceModel"
  value        = var.openai_inference_model

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}

resource "azurerm_key_vault_secret" "cogAccOpenAiEmbeddingsModel" {
  count = local.keyvault_enabled && local.cognitive_services_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "cogAccOpenAiEmbeddingsModel"
  value        = var.openai_embeddings_model

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}

# Cognitive Services
# - Speech
resource "azurerm_key_vault_secret" "cogAccSpeechEndpoint" {
  count = local.keyvault_enabled && local.cognitive_services_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "cogAccSpeechEndpoint"
  value        = module.speech[0].cognitive_account.endpoint

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}

resource "azurerm_key_vault_secret" "cogAccSpeechLocation" {
  count = local.keyvault_enabled && local.cognitive_services_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "cogAccSpeechLocation"
  value        = module.speech[0].cognitive_account.location

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}

resource "azurerm_key_vault_secret" "cogAccSpeechPrimaryAccessKey" {
  count = local.keyvault_enabled && local.cognitive_services_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "cogAccSpeechPrimaryAccessKey"
  value        = module.speech[0].cognitive_account.primary_access_key

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}

resource "azurerm_key_vault_secret" "cogAccSpeechSecondaryAccessKey" {
  count = local.keyvault_enabled && local.cognitive_services_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "cogAccSpeechSecondaryAccessKey"
  value        = module.speech[0].cognitive_account.secondary_access_key

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}

# Application Insights
resource "azurerm_key_vault_secret" "applicationInsightsConnectionString" {
  count = local.keyvault_enabled && local.appinsights_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "applicationInsightsConnectionString"
  value        = azurerm_application_insights.this[0].connection_string

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}

# ASI internals
resource "azurerm_key_vault_secret" "asiServicePrincipalClientId" {
  count = local.keyvault_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "asiServicePrincipalClientId"
  value        = var.asi_sp_client_id

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}

resource "azurerm_key_vault_secret" "asiServicePrincipalSecret" {
  count = local.keyvault_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "asiServicePrincipalSecret"
  value        = var.asi_sp_client_secret

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}

resource "random_password" "asi" {
  count       = local.keyvault_enabled ? 3 : 0
  length      = 20
  min_upper   = 4
  min_lower   = 4
  min_numeric = 4
  special     = true
}

resource "azurerm_key_vault_secret" "asiReservoirBackendSecret" {
  count = local.keyvault_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "asiReservoirBackendSecret"
  value        = random_password.asi[0].result

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}

resource "azurerm_key_vault_secret" "asiJwtSecret" {
  count = local.keyvault_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "asiJwtSecret"
  value        = random_password.asi[1].result

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}

resource "azurerm_key_vault_secret" "asiCookieEncryptionKey" {
  count = local.keyvault_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "asiCookieEncryptionKey"
  value        = random_password.asi[2].result

  depends_on = [
    time_sleep.wait_for_kv_role_assignment[0]
  ]
}
