# Provision the needed resources
module "system-services" {
  source = "../system-services"

  subscription_id           = var.subscription_id
  location                  = var.location
  domain_id                 = var.domain_id
  aks_oidc_issuer           = module.cluster.kubernetes_cluster.oidc_issuer_url
  oidc_client_id            = var.oidc_idp_client_id
  oidc_client_secret        = var.oidc_idp_client_secret
  oidc_discovery_endpoint   = local.oidc_metadata
  admin_user_object_ids     = var.system_services_keyvault_admin_user_object_ids
  secrets_reader_object_ids = var.system_services_keyvault_secrets_reader_object_ids
  keyvault_allowed_cidrs    = var.system_services_keyvault_allowed_cidrs

  subnet_privatelinkendpoints = {
    id = module.aks-spoke.subnet_privatelinkendpoints.id
  }

  keyvault_private_dns_zone = {
    id = module.keyvault_private_dns.private_dns_zone.id
  }
}


