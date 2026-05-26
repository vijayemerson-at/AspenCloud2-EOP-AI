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
  description = "An identifier used in names of resources created by this module"
  type        = string
}

# Network
variable "virtual_network_address_space" {
  type    = list(string)
  default = ["10.240.0.0/16"]
}

variable "subnet_privatelinkendpoints_address_prefixes" {
  type    = list(string)
  default = ["10.240.4.32/27"]
}

variable "subnet_aksilb_address_prefixes" {
  type    = list(string)
  default = ["10.240.4.0/28"]
}

variable "subnet_applicationgateway_address_prefixes" {
  type    = list(string)
  default = ["10.240.5.0/24"]
}

variable "subnet_clusternodes_address_prefixes" {
  type    = list(string)
  default = ["10.240.0.0/22"]
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

# Service principal to access to Kubernetes cluster
variable "aks_aad_sp_tenant_id" {
  type        = string
  description = "Tenant id of the App Registration"
  default     = ""
}

variable "aks_aad_sp_client_id" {
  type        = string
  description = "Client id of the App Registration"
  default     = ""
}

variable "aks_aad_sp_client_secret" {
  type        = string
  description = "Client secret of the App Registration"
  default     = ""
}

# Kubernetes cluster
variable "cluster_external_dns_zone_name" {
  type        = string
  description = "Domain name to be used for External-DNS for this cluster."
}

variable "cluster_control_plane_authorization_tenant_id" {
  type        = string
  description = "AKS control plane Cluster API authentication tenant. If not provided, local tenantId will be used."
  default     = null
}

variable "cluster_kubernetes_version" {
  type        = string
  description = "Kubernetes version to use"
  default     = "1.34"
}

variable "cluster_orchestrator_version" {
  type        = string
  description = "Cluster node orchestrator version"
  default     = "1.34"
}

variable "cluster_local_account_disabled" {
  type        = bool
  description = "Cluster local account disabled"
  default     = true
}

variable "cluster_admin_microsoft_entra_group_object_ids" {
  type        = list(string)
  description = "Microsoft Entra groups in the identified tenant that will be granted the highly privileged cluster-admin role. If Azure RBAC is used, then this group will get a role assignment to Azure RBAC, else it will be assigned directly to the cluster's admin group."
}

variable "cluster_api_server_authorized_ip_ranges" {
  type        = list(string)
  description = "List of CIDR that will be authorized to resources. This is needed to allow private cluster access"
  default     = []
}

variable "cluster_node_os_upgrade_channel" {
  type        = string
  description = "The upgrade channel for this Kubernetes Cluster Nodes' OS Image."
  default     = "NodeImage"
}

variable "cluster_automatic_upgrade_channel" {
  type        = string
  description = "The upgrade channel for this Kubernetes Cluster."
  nullable    = true
  default     = "patch"
}

variable "cluster_maintenance_window" {
  type = object({
    allowed = optional(object({
      day   = string
      hours = list(string)
    }))
    not_allowed = optional(object({
      start = string
      end   = string
    }))
  })
  description = "Generic maintenance window that defines the allowed and not allowed time-slots for Kubernetes and node OS maintenance."
  nullable    = true
  default     = null
}

variable "cluster_maintenance_window_auto_upgrade" {
  type = object({
    frequency    = string
    interval     = number
    duration     = number
    day_of_week  = optional(string)
    day_of_month = optional(string)
    week_index   = optional(string)
    start_time   = optional(string)
    utc_offset   = optional(string)
    start_date   = optional(string)
    not_allowed = optional(object({
      start = string
      end   = string
    }))
  })
  nullable = true
  default  = null
}

variable "cluster_maintenance_window_node_os" {
  type = object({
    frequency    = string
    interval     = number
    duration     = number
    day_of_week  = optional(string)
    day_of_month = optional(string)
    week_index   = optional(string)
    start_time   = optional(string)
    utc_offset   = optional(string)
    start_date   = optional(string)
    not_allowed = optional(object({
      start = string
      end   = string
    }))
  })
  nullable = true
  default  = null
}

# Gitops
variable "gitops_organisation_name" {
  type        = string
  description = "Name of the git organisation that will be owner of the created repository"
}

variable "gitops_token" {
  type        = string
  description = "Valid token to access the git organisation"
}

# Chart and Docker registry
variable "aspentech_registry_url" {
  type        = string
  description = "URL of the registry from which the cluster will fetch docker and charts"
}

variable "aspentech_registry_user" {
  type        = string
  description = "User used to access the registry"
}

variable "aspentech_registry_password" {
  type        = string
  description = "Password used to access the registry"
}

variable "aspentech_registry_email" {
  type        = string
  description = "Email used to access the registry"
}

# System Services
variable "software_license_manager_server_url" {
  type        = string
  description = "Url of the Software License Manager server"
}

variable "software_license_manager_buckets" {
  type        = string
  description = "Buckets for the Software License Manager server"
}

variable "system_services_keyvault_allowed_cidrs" {
  type        = list(string)
  description = "List of CIDR that will be authorized to resources. This is needed to allow Key Vault secret creation"
  default     = []
}

variable "system_services_keyvault_admin_user_object_ids" {
  type        = list(string)
  description = "Object IDs of groups that will get admin privileges to the key vault resources"
  default     = []
}

variable "system_services_keyvault_secrets_reader_object_ids" {
  type        = list(string)
  description = "Object IDs of groups that will get read secret privileges to the key vault resources"
  default     = []
}
