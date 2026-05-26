locals {
  keyvault_enabled = true
  service_accounts = [ # hardcoded values shared with the product chart
    { name : "envoy-gateway-system", namespace : "envoy-gateway-system" },
    { name : "aspencloud", namespace : "aspencloud" }
  ]

  tags = {
    DomainId    = var.domain_id
    ProductName = var.component_name
  }
}

#### Core-services
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
  suffix  = [var.component_name, var.domain_id]
}

resource "azurerm_resource_group" "app" {
  location = var.location
  name     = module.naming.resource_group.name_unique

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
  for_each = { for key, sa in local.service_accounts :
  key => sa if local.keyvault_enabled }

  name                = "aks-identity-${each.value.name}"
  resource_group_name = azurerm_resource_group.app.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer
  parent_id           = azurerm_user_assigned_identity.this[0].id
  subject             = "system:serviceaccount:${each.value.namespace}:${each.value.name}"

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
  admin_user_object_ids = var.admin_user_object_ids
  secrets_reader_object_ids = concat(var.secrets_reader_object_ids, [
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

resource "azurerm_key_vault_secret" "oidcClientId" {
  count = local.keyvault_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "oidcClientId"
  value        = var.oidc_client_id
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "oidcClientSecret" {
  count = local.keyvault_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "oidcClientSecret"
  value        = var.oidc_client_secret
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

resource "azurerm_key_vault_secret" "oidcDiscoveryEndpoint" {
  count = local.keyvault_enabled ? 1 : 0

  key_vault_id = module.kv[0].key_vault.id
  name         = "oidcDiscoveryEndpoint"
  value        = var.oidc_discovery_endpoint
  depends_on   = [time_sleep.wait_for_kv_role_assignment[0]]
}

