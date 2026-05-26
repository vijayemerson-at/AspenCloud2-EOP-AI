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

variable "key_vault" {
  type = object({
    enable_rbac_authorization       = optional(bool, true)
    enabled_for_deployment          = optional(bool)
    enabled_for_disk_encryption     = optional(bool)
    enabled_for_template_deployment = optional(bool)
    name                            = string
    # public_network_access_enabled = optional(bool)
    purge_protection_enabled   = optional(bool)
    sku_name                   = string
    soft_delete_retention_days = optional(number)
    tags                       = optional(map(string))
    tenant_id                  = optional(string)
    network_acls = optional(object({
      bypass   = optional(string, "AzureServices")
      ip_rules = optional(set(string), [])
      # virtual_network_subnet_ids = set(string)
    }), {})
  })
}

# variable "purge_key_vault" {
#   description = "Whether to purge the key vault after deletion"
#   type        = bool
#   default     = false
# }

variable "private_endpoint" {
  type = object({
    subnet_id = string
    tags      = optional(map(string), {})
    private_dns_zone_group = object({
      private_dns_zone_ids = list(string)
    })
  })
}

# # Requires the Service Principal have Microsoft Graph User.Read.All
# variable "admin_users" {
#   type    = list(string)
#   default = []
# }

# Use the following if the Entra ID Administration has not granted the Service Principal User.Read.All
variable "admin_user_object_ids" {
  type    = list(string)
  default = []
}

variable "secrets_reader_object_ids" {
  type    = list(string)
  default = []
}