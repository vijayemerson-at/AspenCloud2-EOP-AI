data "azurerm_subscription" "current" {}

locals {
  user_assigned_identity_name        = "${substr(var.managed_identity_prefix, 0, 123)}-keda"
  federated_identity_credential_name = "kedafedidentity"
  keda_namespace                     = "keda"
  service_account_name               = "keda-operator"
  keda = templatefile(
    "${path.module}/files/keda/keda.yaml.tftpl",
    {
      service_account_name = local.service_account_name
      namespace            = local.keda_namespace
      clientId             = azurerm_user_assigned_identity.keda.client_id
    }
  )
  keda_helm_release = templatefile(
    "${path.module}/files/keda/keda_helm_release.yaml.tftpl",
    {
      namespace          = local.keda_namespace
      clientId           = azurerm_user_assigned_identity.keda.client_id
      tenantId           = data.azurerm_subscription.current.tenant_id
      keda_chart_version = "2.19.0",
      image_registry     = local.cluster_primary_container_registry_host,
    }
  )
}

## ---------------------------------------------------
# Keda Namespace
## ---------------------------------------------------
resource "kubernetes_namespace" "keda" {
  metadata {
    name = local.keda_namespace
  }
}

## ---------------------------------------------------
# Azure Assigned Identity
## ---------------------------------------------------
resource "azurerm_user_assigned_identity" "keda" {
  location            = var.location
  name                = local.user_assigned_identity_name
  resource_group_name = var.resource_group.name
  depends_on          = [kubernetes_namespace.keda]
}

## ---------------------------------------------------
# Role Assignment 
## ---------------------------------------------------
resource "azurerm_role_assignment" "keda" {
  scope                = azurerm_monitor_workspace.this.id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_user_assigned_identity.keda.principal_id
  depends_on           = [azurerm_user_assigned_identity.keda]
}

## ---------------------------------------------------
# Azure Federated Identity Credentials
## ---------------------------------------------------
resource "azurerm_federated_identity_credential" "keda" {
  name                = local.federated_identity_credential_name
  resource_group_name = var.resource_group.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.kubernetes_cluster.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.keda.id
  subject             = "system:serviceaccount:${local.keda_namespace}:${local.service_account_name}"
  depends_on          = [azurerm_user_assigned_identity.keda]
}

