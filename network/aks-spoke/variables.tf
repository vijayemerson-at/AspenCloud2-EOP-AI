# Variables
# variable "hubVnetResourceId" {
#   description = "Resource ID of the hub virtual network"
#   type        = string
# }

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

variable "domain_id" {
  description = "An identifier used in names of resources created by this module"
  type        = string
}


variable "virtual_network" {
  type = object({
    address_space = optional(list(string), ["10.240.0.0/16"])
    tags          = optional(map(string), {})
  })
  default = {}
}

variable "subnet_privatelinkendpoints" {
  type = object({
    address_prefixes = optional(list(string), ["10.240.4.32/28"])
    tags             = optional(map(string), {})
  })
  default = {}
}

variable "nsg_privatelinkendpoints" {
  type = object({
    security_rules = optional(list(object({
      name                       = optional(string)
      priority                   = optional(string)
      direction                  = optional(string)
      access                     = optional(string)
      protocol                   = optional(string)
      source_address_prefix      = optional(string)
      source_port_range          = optional(string)
      destination_address_prefix = optional(string)
      destination_port_range     = optional(string)
    })), [])
  })
  default = {}
}

variable "subnet_aksilb" {
  type = object({
    address_prefixes = optional(list(string), ["10.240.4.0/28"])
    tags             = optional(map(string), {})
  })
  default = {}
}

variable "subnet_applicationgateway" {
  type = object({
    address_prefixes = optional(list(string), ["10.240.5.0/24"])
    tags             = optional(map(string), {})
  })
  default = {}
}

variable "subnet_clusternodes" {
  type = object({
    address_prefixes = optional(list(string), ["10.240.0.0/22"])
    tags             = optional(map(string), {})
  })
  default = {}
}
