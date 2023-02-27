locals {
  resource_group_name = "RG-for-WebApss"
  location            = "North Europe"
}

resource "azurerm_resource_group" "resource_group" {
  name     = local.resource_group_name
  location = local.location
}

resource "azurerm_app_service_plan" "service_plan" {
  name                = "new-service-plan"
  location            = local.location
  resource_group_name = local.resource_group_name
  sku {
    tier = "Basic"
    size = "B1"
  }

  depends_on = [
    azurerm_resource_group.resource_group
  ]
}

resource "azurerm_app_service" "app_service" {
  name                = "the-unique-one-service-app"
  resource_group_name = local.resource_group_name
  location            = local.location
  app_service_plan_id = azurerm_app_service_plan.service_plan.id
  site_config {
    dotnet_framework_version = "v6.0"
  }

  source_control {
    repo_url           = "  webapp"
    branch             = "master"
    manual_integration = true
    use_mercurial      = false
  }
}