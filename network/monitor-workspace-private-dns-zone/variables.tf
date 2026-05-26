variable "resource_group_name" {
  description = "Name of the resource group"
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

variable "private_dns_zone" {
  type = object({
    tags = optional(map(string), {})
  })
  default = {}
}

variable "private_dns_zone_virtual_network_link" {
  type = object({
    virtual_network_id = string
    tags               = optional(map(string), {})
  })
}