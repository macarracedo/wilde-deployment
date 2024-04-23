terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "wilde-common-rg"
    storage_account_name = "wildeterraformbackend"
    container_name       = "terraform-backend"
    key                  = "terraform.tfstate"
  }

}

provider "azurerm" {
  features {}
}