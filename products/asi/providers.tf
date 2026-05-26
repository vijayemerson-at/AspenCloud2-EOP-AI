terraform {
  required_version = ">= 1.10.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.61.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "2.53.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }

    time = {
      source  = "hashicorp/time"
      version = "0.13.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

terraform {
  backend "azurerm" {
    storage_account_name = ""
    container_name       = ""
    key                  = "asi.terraform.tfstate"
    resource_group_name  = ""
  }
}