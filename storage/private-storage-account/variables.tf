variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "storage_account" {
  description = "Configuration for the storage account"
  type = object({
    name                      = optional(string)
    kind                      = optional(string, "StorageV2")
    tier                      = optional(string, "Standard")
    replication_type          = optional(string, "LRS")
    access_tier               = optional(string, "Hot")
    is_hns_enabled            = optional(bool, false)
    shared_access_key_enabled = optional(bool)
    tags                      = optional(map(string), {})
    network_rules = optional(object({
      default_action = optional(string, "Deny")
      ip_rules       = optional(list(string), [])
      bypass         = optional(set(string), ["Metrics", "Logging"])
    }), {})
    blob_properties = optional(object({
      cors_rule = optional(object({
        allowed_headers    = list(string),
        allowed_methods    = list(string),
        allowed_origins    = list(string),
        exposed_headers    = list(string),
        max_age_in_seconds = number
      }))
      versioning_enabled = optional(bool, false)
      delete_retention_policy = optional(object({
        days                     = optional(number)
        permanent_delete_enabled = optional(bool)
      }), {})
      }), {
      delete_retention_policy = {}
    })
  })
}

variable "storage_account_queue_properties" {
  type = object({
    cors_rule = optional(object({
      allowed_headers    = list(string),
      allowed_methods    = list(string),
      allowed_origins    = list(string),
      exposed_headers    = list(string),
      max_age_in_seconds = number
    }))
    logging = optional(object({
      delete                = bool,
      read                  = bool,
      version               = string,
      write                 = bool,
      retention_policy_days = optional(number, 7)
    })),
    minute_metrics = optional(object({
      enabled               = bool,
      version               = string,
      include_apis          = optional(bool, false),
      retention_policy_days = optional(number, 1)
    })),
    hour_metrics = optional(object({
      enabled               = bool,
      version               = string,
      include_apis          = optional(bool, false),
      retention_policy_days = optional(number, 7)
    }))
  })
  default = {}
}

variable "storage_containers" {
  description = "A list of storage container configurations."
  type = list(object({
    name                  = string
    container_access_type = optional(string, "private")
  }))
  default = []
}

variable "storage_queues" {
  description = "A list of queue configurations."
  type = list(object({
    name = string
  }))
  default = []
}

variable "storage_shares" {
  description = "A list of file shares configurations."
  type = list(object({
    name        = string
    access_tier = optional(string, "TransactionOptimized")
    quota       = number
  }))
  default = []
}

variable "private_endpoints" {
  type = list(object({
    subnet_id = string
    private_service_connection = object({
      subresource_names = list(string)
    })
    private_dns_zone_group = object({
      name                 = string
      private_dns_zone_ids = list(string)
    })
    tags = optional(map(string), {})
  }))
  default = []
}