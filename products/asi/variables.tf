variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
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

variable "domain_id" {
  description = "Unique prefix for the resources managed by this domain"
  type        = string
  default     = "dev"
}

variable "aks_oidc_issuer" {
  description = "AKS OIDC issuer"
  type        = string
}

variable "instance_domain_url" {
  description = "Domain url, for example https://my.domain.com that will be used by this software. It's used to allow CORS on storage account."
  type        = string
}

variable "product_name" {
  description = "Unique product name for the resources used by this product"
  type        = string
  default     = "asi"
}

variable "asi_sp_object_id" {
  description = "Object ID of the Service Principal for ASI"
  type        = string
  default     = ""
  validation {
    condition = (
      length(trim(var.asi_sp_object_id, " ")) > 0 &&
      length(trim(var.asi_sp_client_id, " ")) > 0 &&
      length(trim(var.asi_sp_client_secret, " ")) > 0 &&
      length(trim(var.asi_sp_tenant_id, " ")) > 0
    )
    error_message = "You must provide all asi_sp_* variables: asi_sp_object_id, asi_sp_client_id, asi_sp_client_secret, asi_sp_tenant_id."
  }
}

variable "asi_sp_client_id" {
  description = "Client ID of the Service Principal for ASI"
  type        = string
  default     = ""
}

variable "asi_sp_client_secret" {
  description = "Client Secret of the Service Principal for ASI"
  type        = string
  default     = ""
  sensitive   = true
}

variable "asi_sp_tenant_id" {
  description = "Tenant ID of the Service Principal for ASI"
  type        = string
  default     = ""
}

# OIDC
variable "oidc_tenant_id" {
  type        = string
  description = "Tenant id of the App Registration"
  default     = ""
}

variable "oidc_idp_client_id" {
  type        = string
  description = "Client id of the App Registration"
  default     = ""
}

variable "oidc_idp_client_secret" {
  type        = string
  description = "Client secret of the App Registration"
  default     = ""
}

# Network
variable "subnet_privatelinkendpoints" {
  description = "Id of the subnet that will contain the private link endpoints"
  type = object({
    id               = string
    address_prefixes = optional(set(string), [])
  })
}

variable "openai_private_dns_zone" {
  description = "Id of the private dns zone for OpenAI"
  type = object({
    id = string
  })
}

variable "cognitive_services_private_dns_zone" {
  description = "Id of the private dns zone for Cognitive Services"
  type = object({
    id = string
  })
}

variable "queue_private_dns_zone" {
  description = "Id of the private dns zone for Queue"
  type = object({
    id = string
  })
}

variable "blob_private_dns_zone" {
  description = "Id of the private dns zone for Blob"
  type = object({
    id = string
  })
}

variable "eventgrid_domain_private_dns_zone" {
  description = "Id of the private dns zone for EventGrid Domain"
  type = object({
    id = string
  })
}

variable "redis_managed_private_dns_zone" {
  description = "Id of the private dns zone for Azure Managed Redis (Enterprise)"
  type = object({
    id = string
  })
}

variable "postgres_private_dns_zone" {
  description = "Id of the private dns zone for Postgres"
  type = object({
    id = string
  })
}

variable "keyvault_private_dns_zone" {
  description = "Id of the private dns zone for Keyvault"
  type = object({
    id = string
  })
}

variable "keyvault_allowed_cidrs" {
  type        = list(string)
  description = "List of CIDR that will be authorized to resources. This is needed to allow Key Vault secret creation"
  default     = []
}

variable "postgres_allowed_cidrs" {
  type        = list(string)
  description = "List of CIDR that will be authorized to resources."
  default     = []
}

# Security
variable "keyvault_admin_user_object_ids" {
  type        = list(string)
  description = "Object IDs of groups that will get admin privileges to the resources."
  default     = []
}

variable "keyvault_secrets_reader_object_ids" {
  type        = list(string)
  description = "Object IDs of groups that will get read secret privileges to the key vault resources."
  default     = []
}

## Postgres
variable "pg_admins" {
  type = list(object({
    object_id      = string
    principal_name = string,
    principal_type = string,
  }))
  description = <<EOT
    Those are Active Directory entries that will become administrators of the Postgres Flexible Server
    pg_admins = {
      object_id : "The object ID of a user, service principal or security group in the Azure Active Directory tenant set as the Flexible Server Admin. Changing this forces a new resource to be created."
      principal_name : "The name of Azure Active Directory principal. Changing this forces a new resource to be created."
      principal_type : "The type of Azure Active Directory principal. Possible values are Group, ServicePrincipal and User. Changing this forces a new resource to be created."
    }
  EOT
  default     = []
}

# OpenAi service deployment 

# Inference model
variable "openai_inference_model" {
  description = "Name of the OpenAI inference deployment: gpt-5-mini (default) or gpt-5.3-codex"
  type        = string
  default     = "gpt-5-mini"
}
# versions: 
# gpt-5.3-codex: 2026-02-24
# gpt-5-mini: 2025-08-07

variable "openai_inference_model_capacity" {
  description = "Capacity of OpenAI inference deployment (TPM - Tokens Per Minute), default 2500"
  type        = number
  default     = 2500
}
# Embeddings model
variable "openai_embeddings_model" {
  description = "Name of the OpenAI embeddings model deployment: text-embedding-3-small (default) or text-embedding-3-large"
  type        = string
  default     = "text-embedding-3-small"
}

# Speech Services
variable "speech_services_sku" {
  description = "SKU for Speech Services. F0 (free tier, 1 per subscription limit), S0 (standard pay-as-you-go), S1-S5 (standard reserved capacity), E0 (enterprise tier)"
  type        = string
  default     = "F0"
  validation {
    condition     = contains(["F0", "S0", "S1", "S2", "S3", "S4", "S5", "E0"], var.speech_services_sku)
    error_message = "Speech Services SKU must be one of: F0, S0, S1, S2, S3, S4, S5, E0."
  }
}

# Application Insights
variable "appinsights_enabled" {
  description = "Enable Application Insights for application monitoring and telemetry"
  type        = bool
  default     = false
}

