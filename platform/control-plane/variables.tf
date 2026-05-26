variable "resource_group" {
  description = "Resource group"
  type = object({
    name = string
    id   = string
  })
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

variable "managed_identity_prefix" {
  description = "Prefix for the managed identities"
  type        = string
  default     = "uai"
}

# Info and Service principal to access to Kubernetes cluster
variable "kubernetes_cluster" {
  type = object({
    id                     = string
    name                   = string
    oidc_issuer_url        = string
    host                   = string
    cluster_ca_certificate = string
    aad_sp_tenant_id       = string
    aad_sp_client_id       = string
    aad_sp_client_secret   = string
  })
  description = <<EOT
  Info and Service principal to access to Kubernetes cluster
  kubernetes_cluster = {
    id : "Id of the AKS cluster"
    name : "Name of the AKS cluster"
    oidc_issuer_url : "The OIDC issuer URL that is associated with the AKS cluster"
    host : "Host of the AKS cluster to be used to access it"
    cluster_ca_certificate : "Base64 encoded CA certificate of the AKS cluster to be used to access it"
    aad_sp_tenant_id : "Tenant id of the App Registration"
    aad_sp_client_id : "Client id of the App Registration"
    aad_sp_client_secret : "Client secret of the App Registration"
  }
  EOT
}

# variable "log_aggregation_mode" {
#   type        = string
#   description = "Whether to use a log aggregator like Azure Log Analytics or just Kubernetes logs."
#   default     = "azure-log-analytics"
#   validation {
#     condition = contains(["azure-log-analytics", "kubernetes-only"], var.log_aggregation_mode)
#     error_message = "log_aggregation_mode must be one of [\"azure-log-analytics\", \"kubernetes-only\"]"
#   }
# }

variable "fluxcd" {
  type = object({
    namespace                           = optional(string, "flux-system")
    external_repository_ssh_known_hosts = optional(string, "")
    repository_scan_interval            = optional(string, "3m0s")
    artifact_repository_scan_interval   = optional(string, "3m")
  })
  description = <<EOT
    FluxCD related variables
    fluxcd = {
      namespace : "Kubernetes namespace in which to install flux"
      external_repository_ssh_known_hosts : "Inject ssh known hosts to flux when using an external repository"
      repository_scan_interval : "Scan interval in minutes to look for changes in the repository"
      artifact_repository_scan_interval : "Scan interval in minutes to look for changes in the artifact repositories"
    }
  EOT
}

variable "gitops" {
  type = object({
    organization_name           = string
    external_repository_address = optional(string, "")
    repository_name             = string
    repository_target_branch    = optional(string, "main")
    repository_target_path      = optional(string, "manifests")
    helm_repositories = optional(map(object({
      url      = string
      username = string
      password = string
      type     = string
    })), {})
  })
  description = <<EOT
    GitOps related variables
    gitops = {
      organization_name : "Name of the github organization containing the products to deploy on the instance"
      external_repository_address : "Configure flux to use an external repository at specified address"
      repository_name : "Name of the Git repository"
      repository_target_branch : "Branch to target in the Git Repository"
      repository_target_path : "Root directory in the repository for manifests"
      helm_repositories : Dict of repositories to inject in the cluster in the form of {"repo_name": {"url": "repo_url", "username": "repo_user", "password": "repo_pass"}}
    }
  EOT
}

variable "global" {
  type = object({
    container_image_repositories = optional(map(object({
      host     = string
      username = string
      password = string
      email    = string
    })), {})
  })
  description = <<EOT
    Global variables
    global = {
      container_image_repositories : Dict of container image repositories to inject in the cluster in the form of {"repo_name": {"host": "repo_host", "username": "repo_user", "password": "repo_pass", "email": "repo_email"}}
    }
  EOT
}

variable "monitor_workspace" {
  type = object({
    name                          = string
    public_network_access_enabled = optional(bool, false)
    tags                          = optional(map(string), {})
  })
}

variable "dashboard_grafana" {
  type = object({
    name                                   = string
    grafana_major_version                  = optional(string, 11)
    api_key_enabled                        = optional(bool, true)
    auto_generated_domain_name_label_scope = optional(string, "TenantReuse")
    deterministic_outbound_ip_enabled      = optional(bool, false)
    smtp = optional(object({
      enabled                   = optional(bool, false)
      host                      = string
      user                      = string
      password                  = string
      start_tls_policy          = string
      from_address              = string
      from_name                 = optional(string)
      verification_skip_enabled = optional(bool, false)
    }))
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))
    public_network_access_enabled = optional(bool, false)
    sku                           = optional(string, "Standard")
    zone_redundancy_enabled       = optional(bool, false)
    tags                          = optional(object({}), {})
  })
}

variable "monitor_workspace_private_endpoint" {
  type = object({
    subnet_id = string
    tags      = optional(map(string), {})
    private_dns_zone_group = object({
      private_dns_zone_ids = list(string)
    })
  })
}

variable "dashboard_grafana_private_endpoint" {
  type = object({
    subnet_id = string
    tags      = optional(map(string), {})
    private_dns_zone_group = object({
      private_dns_zone_ids = list(string)
    })
  })
}

variable "system_services" {
  type = object({
    oidc_issuer                                = string
    oidc_metadata                              = string
    cluster_external_dns_zone_name             = string
    key_vault_name                             = string
    key_vault_tenant_id                        = string
    key_vault_identity_user_assigned_client_id = string
    software_license_manager_server_url        = string
    software_license_manager_buckets           = string
  })

  description = <<EOT
    System Services variables
    system_services = {
      oidc_issuer : "OpenID secondary access token issuer endpoint"
      oidc_metadata : "OpenID metadata endpoint"
      cluster_external_dns_zone_name : "Domain name used for External-DNS for this cluster"
      key_vault_name : "Key Vault name"
      key_vault_tenant_id : "Key Vault tenant Id"
      key_vault_identity_user_assigned_client_id : "Client Id of the Key Vault user assigned identity"
      software_license_manager_server_url : "Url of the Software License Manager server"
      software_license_manager_buckets : "Buckets for the Software License Manager server"
    }
  EOT
}