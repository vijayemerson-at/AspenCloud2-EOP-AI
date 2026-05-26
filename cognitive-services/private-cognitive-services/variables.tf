variable "location" {
  description = ""
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "cognitive_account" {
  description = "Azure Cognitive Services Account"
  type = object({
    name                       = string
    kind                       = string
    sku_name                   = string
    custom_subdomain_name      = optional(string)
    dynamic_throttling_enabled = optional(bool)
    customer_managed_key = optional(object({
      key_vault_key_id   = string
      identity_client_id = optional(string)
    }))
    fqdns = optional(list(string))
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))
    local_auth_enabled              = optional(bool)
    metrics_advisor_aad_client_id   = optional(string)
    metrics_advisor_aad_tenant_id   = optional(string)
    metrics_advisor_super_user_name = optional(string)
    metrics_advisor_website_name    = optional(string)
    network_acls = optional(object({
      default_action = string
      ip_rules       = optional(list(string), [])
      virtual_network_rules = optional(object({
        subnet_id                            = string
        ignore_missing_vnet_service_endpoint = optional(bool)
      }))
    }))
    outbound_network_access_restricted           = optional(bool)
    public_network_access_enabled                = optional(bool)
    qna_runtime_endpoint                         = optional(string)
    custom_question_answering_search_service_id  = optional(string)
    custom_question_answering_search_service_key = optional(string)
    storage = optional(object({
      storage_account_id = string
      identity_client_id = optional(string)
    }))
    tags = optional(map(string), {})
  })
}

variable "cognitive_deployments" {
  description = "Deployments of the Cognitive Service"
  type = list(object({
    name = string
    model = object({
      format  = string
      name    = string
      version = optional(string)
    })
    sku = object({
      name     = string
      tier     = optional(string)
      size     = optional(number)
      family   = optional(string)
      capacity = optional(number)
    })
    rai_policy_name        = optional(string, "Microsoft.DefaultV2")
    version_upgrade_option = optional(string)
  }))
  default = []
}

variable "private_endpoint" {
  type = object({
    subnet_id = string
    tags      = optional(map(string), {})
    private_dns_zone_group = object({
      private_dns_zone_ids = list(string)
    })
  })
}