locals {
  resource_group_name = "RG-for-Azure-Traffic-Manager"
  location            = "Japan East"
  location2           = "West Europe"
}

resource "azurerm_resource_group" "RG" {
  name     = local.resource_group_name
  location = local.location
}

resource "azurerm_app_service_plan" "Service-Plan1" {
  name                = "first-service-plan"
  resource_group_name = local.resource_group_name
  location            = local.location
  sku {
    tier = "Standard"
    size = "S1"
  }

  depends_on = [
    azurerm_resource_group.RG
  ]
}

resource "azurerm_app_service" "App-Service1" {
  name                = "webapp-114"
  resource_group_name = local.resource_group_name
  location            = local.location
  app_service_plan_id = azurerm_app_service_plan.Service-Plan1.id
  site_config {
    dotnet_framework_version = "v6.0"
  }
  source_control {
    repo_url           = "https://github.com/AmanPathak-dev/Azure-WebApp1-.Net"
    branch             = "master"
    manual_integration = true
    use_mercurial      = false
  }

  depends_on = [
    azurerm_resource_group.RG,azurerm_app_service_plan.Service-Plan1
  ]
}


resource "azurerm_app_service_plan" "Service-Plan2" {
  name                = "second-service-plan"
  resource_group_name = local.resource_group_name
  location            = local.location2
  sku {
    tier = "Standard"
    size = "S1"
  }

  depends_on = [
    azurerm_resource_group.RG
  ]
}

resource "azurerm_app_service" "App-Service2" {
  name                = "webapp-115"
  resource_group_name = local.resource_group_name
  location            = local.location2
  app_service_plan_id = azurerm_app_service_plan.Service-Plan2.id
  site_config {
    dotnet_framework_version = "v6.0"
  }
  source_control {
    repo_url           = "https://github.com/AmanPathak-dev/Azure-WebApp2-.Net"
    branch             = "master"
    manual_integration = true
    use_mercurial      = false
  }

  depends_on = [
    azurerm_resource_group.RG,azurerm_app_service_plan.Service-Plan2
  ]
}

resource "azurerm_traffic_manager_profile" "traffic-manager-115" {
  name                   = "traffic-manager-115"
  resource_group_name    = local.resource_group_name
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "traffic-manager-115"
    ttl           = 100
  }

  monitor_config {
    protocol                     = "HTTPS"
    port                         = 443
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }

  depends_on = [
    azurerm_resource_group.RG,azurerm_app_service_plan.Service-Plan1,azurerm_app_service.App-Service1,azurerm_app_service_plan.Service-Plan2,azurerm_app_service.App-Service2
  ]
}

resource "azurerm_traffic_manager_azure_endpoint" "the-first-one-web-app" {
  name               = "the-first-one-web-app"
  profile_id         = azurerm_traffic_manager_profile.traffic-manager-115.id
  weight             = 100
  priority           = 1
  target_resource_id = azurerm_app_service.App-Service1.id

  depends_on = [
    azurerm_resource_group.RG,azurerm_traffic_manager_profile.traffic-manager-115
  ]
}

resource "azurerm_traffic_manager_azure_endpoint" "the-second-one-web-app" {
  name               = "the-second-one-web-app"
  profile_id         = azurerm_traffic_manager_profile.traffic-manager-115.id
  weight             = 100
  priority           = 2
  target_resource_id = azurerm_app_service.App-Service2.id

  depends_on = [
    azurerm_resource_group.RG,azurerm_traffic_manager_profile.traffic-manager-115
  ]
}