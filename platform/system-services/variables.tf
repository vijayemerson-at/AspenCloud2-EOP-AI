variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Location for the resources"
  type        = string
  default     = "eastus"
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

variable "component_name" {
  description = "Unique name for this component"
  type        = string
  default     = "system"
}

# Network
variable "subnet_privatelinkendpoints" {
  description = "Id of the subnet that will contain the private link endpoints"
  type = object({
    id               = string
    address_prefixes = optional(set(string), [])
  })
}

# OIDC
variable "oidc_client_id" {
  type        = string
  description = "Client id used for OIDC"
  default     = ""
}

variable "oidc_client_secret" {
  type        = string
  description = "Client secret used for OIDC"
  default     = ""
}

variable "oidc_discovery_endpoint" {
  type        = string
  description = "Discovery endpoint used for OIDC"
  default     = ""
}

# Keyvault
variable "keyvault_allowed_cidrs" {
  description = "List of CIDR that will be authorized to resources. This is needed to allow Key Vault secret creation"
  type        = list(string)
  default     = []
}

variable "admin_user_object_ids" {
  description = "Object IDs of groups that will get admin privileges to the key vault resources"
  type        = list(string)
  default     = []
}

variable "secrets_reader_object_ids" {
  description = "Object IDs of groups that will get read secret privileges to the key vault resources"
  type        = list(string)
  default     = []
}

variable "keyvault_private_dns_zone" {
  description = "Id of the private dns zone for Key Vault"
  type = object({
    id = string
  })
}

