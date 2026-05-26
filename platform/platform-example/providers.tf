provider "azurerm" {
  subscription_id = var.subscription_id
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 15
  host                   = module.cluster.kubernetes_cluster.host
  cluster_ca_certificate = base64decode(module.cluster.kubernetes_cluster.cluster_ca_certificate)
  load_config_file       = false
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args = [
      "get-token",
      "--login",
      "spn",
      "--environment",
      "AzurePublicCloud",
      "--client-id",
      var.aks_aad_sp_client_id,
      "--client-secret",
      var.aks_aad_sp_client_secret,
      "--tenant-id",
      var.aks_aad_sp_tenant_id,
      "--server-id",
      "6dae42f8-4368-4678-94ff-3960e28e3630"
    ]
    command = "kubelogin"
  }
}

provider "kubernetes" {
  host                   = module.cluster.kubernetes_cluster.host
  cluster_ca_certificate = base64decode(module.cluster.kubernetes_cluster.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args = [
      "get-token",
      "--login",
      "spn",
      "--environment",
      "AzurePublicCloud",
      "--client-id",
      var.aks_aad_sp_client_id,
      "--client-secret",
      var.aks_aad_sp_client_secret,
      "--tenant-id",
      var.aks_aad_sp_tenant_id,
      "--server-id",
      "6dae42f8-4368-4678-94ff-3960e28e3630"
    ]
    command = "kubelogin"
  }
}

provider "github" {
  owner = var.gitops_organisation_name
  token = var.gitops_token
}

terraform {
  required_version = ">= 1.10.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.61.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }

    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }
  }
}

terraform {
  backend "azurerm" {
    storage_account_name = ""
    container_name       = ""
    key                  = "platform.terraform.tfstate"
    resource_group_name  = ""
  }
}