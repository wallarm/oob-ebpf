terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "github-ci-tfstate"
    storage_account_name = "tfstate20977"
    container_name       = "tfstate"
  }
}

provider "azurerm" {
  features {}
}