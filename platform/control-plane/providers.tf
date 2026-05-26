terraform {
  required_version = ">= 1.10.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.61.0"
    }

    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }
  }
}
