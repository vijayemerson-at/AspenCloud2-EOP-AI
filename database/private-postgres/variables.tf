variable "location" {
  description = "The Azure Region where the PostgreSQL Flexible Server should exist. Changing this forces a new PostgreSQL Flexible Server to be created."
  default     = "eastus"
  type        = string
}

variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  default     = ""
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "postgresql_flexible_server" {
  type = object({
    name                   = string
    administrator_login    = optional(string)
    administrator_password = optional(string)
    authentication = optional(object({
      active_directory_auth_enabled = optional(bool, false)
      password_auth_enabled         = optional(bool, true)
      tenant_id                     = optional(string)
    }))
    backup_retention_days = optional(number, 7)
    customer_managed_key = optional(object({
      key_vault_key_id                     = string
      primary_user_assigned_identity_id    = optional(string)
      geo_backup_key_vault_key_id          = optional(string)
      geo_backup_user_assigned_identity_id = optional(string)
    }))
    geo_redundant_backup_enabled = optional(bool, true)
    create_mode                  = optional(string, "Default")
    delegated_subnet_id          = optional(string)
    private_dns_zone_id          = optional(string)
    high_availability = optional(object({
      mode                      = string
      standby_availability_zone = optional(string, "1")
    }))
    identity = optional(object({
      type         = optional(string, "UserAssigned")
      identity_ids = list(string)
    }))
    maintenance_window = optional(object({
      day_of_week  = optional(number, 0)
      start_hour   = optional(number, 0)
      start_minute = optional(number, 0)
    }))
    point_in_time_restore_time_in_utc = optional(string)
    replication_role                  = optional(string)
    sku_name                          = optional(string, "GP_Standard_D2ds_v4")
    source_server_id                  = optional(string)
    auto_grow_enabled                 = optional(bool, false)
    storage_mb                        = optional(number, 32768)
    storage_tier                      = optional(string)
    tags                              = optional(map(string))
    version                           = optional(string, "16")
    zone                              = optional(string, "1")
  })
}

variable "server_configurations" {
  description = "PostgreSQL server configurations to add"
  type        = map(string)
  default     = {}
}

variable "allowed_cidrs" {
  type        = map(string)
  default     = {}
  description = "Map of authorized cidrs to connect to database"
}

variable "allow_azure_services_ips" {
  description = "Allow Azure Service IPs to connect to database"
  type        = bool
  default     = false
}

variable "allow_all_ips" {
  description = "Allow all IPs to connect to database"
  type        = bool
  default     = false
}

variable "active_directory_administrators" {
  type = list(object({
    principal_name = string,
    principal_type = string,
    object_id      = string
  }))
  default = []
}

variable "databases" {
  type = list(object({
    name      = string
    charset   = optional(string, "utf8")
    collation = optional(string, "en_US.utf8")
  }))
  description = <<EOT
    databases = {
      name : "Specifies the name of the PostgreSQL Database, which needs to be a valid PostgreSQL identifier. Changing this forces a new Azure PostgreSQL Flexible Server Database to be created."
      charset : "Specifies the Charset for the Azure PostgreSQL Flexible Server Database, which needs to be a valid PostgreSQL Charset. Defaults to UTF8. Changing this forces a new Azure PostgreSQL Flexible Server Database to be created."
      collation : "Specifies the Collation for the Azure PostgreSQL Flexible Server Database, which needs to be a valid PostgreSQL Collation. Defaults to en_US.utf8. Changing this forces a new Azure PostgreSQL Flexible Server Database to be created."
    }
  EOT
  default     = []
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
