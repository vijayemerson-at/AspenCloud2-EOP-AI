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

variable "eventgrid_domain" {
  type = object({
    name = string
    identity = optional(object({
      type         = optional(string, "SystemAssigned")
      identity_ids = optional(list(string))
    }), {})
    input_schema = optional(string, "EventGridSchema")
    input_mapping_fields = optional(object({
      id           = optional(string)
      topic        = optional(string)
      event_type   = optional(string)
      data_version = optional(string)
      subject      = optional(string)
    }))
    input_mapping_default_values = optional(object({
      event_type   = optional(string)
      data_version = optional(string)
      subject      = optional(string)
    }))
    local_auth_enabled                        = optional(bool, true)
    public_network_access_enabled             = optional(bool, false) # (Optional) Whether public network access is enabled 
    auto_create_topic_with_first_subscription = optional(bool, true)
    auto_delete_topic_with_last_subscription  = optional(bool, true)
    tags                                      = optional(map(string), {})

    allowedPublicIpMasks = optional(list(string), [])
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
