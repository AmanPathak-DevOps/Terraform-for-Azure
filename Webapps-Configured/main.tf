locals {
  resource_group_name = "rg-for-webapps"
  location            = "North Europe"
}

resource "azurerm_resource_group" "rg-for-webapps" {
  name = local.resource_group_name
  location            = local.location
}

resource "azurerm_app_service_plan" "service-plan" {
  name                = "whateveryoucanwritehere"
  resource_group_name = local.resource_group_name
  location            = local.location

  sku {
    tier = "Free"
    size = "F1"
  }
}

resource "azurerm_app_service" "app-sernvice" {
  name                = "youcanwriteanythinghere"
  resource_group_name = local.resource_group_name
  location            = local.location
  app_service_plan_id = azurerm_app_service_plan.service-plan.id
}
