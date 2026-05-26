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

variable "redis" {
  type = object({
    name                      = string
    sku_name                  = string
    high_availability_enabled = optional(bool, true)

    default_database = optional(object({
      access_keys_authentication_enabled = optional(bool, false)
    }))

    customer_managed_key = optional(object({
      key_vault_key_id          = string
      user_assigned_identity_id = string
    }), null)

    client_protocol   = optional(string, "Encrypted")
    eviction_policy   = optional(string, "VolatileLRU")
    clustering_policy = optional(string, "OSSCluster")

    public_network_access = optional(string, "Disabled")

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }), null)

    minimum_tls_version = optional(string, "1.2")

    persistence_append_only_file_backup_frequency = optional(string, null)
    persistence_redis_database_backup_frequency   = optional(string, null)

    modules = optional(list(object({
      name = string
      args = optional(string)
    })), [])

    subnet_id                 = optional(string)
    private_static_ip_address = optional(string)

    tags = optional(map(string), {})
  })
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