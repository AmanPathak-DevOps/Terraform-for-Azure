resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_name
  location = var.location
}