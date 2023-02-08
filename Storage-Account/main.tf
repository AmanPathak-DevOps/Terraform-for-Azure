resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_name
  location = var.location
}

resource "azurerm_storage_account" "storage_account" {
  name                          = var.storage_name
  resource_group_name           = azurerm_resource_group.resource_group.name
  location                      = azurerm_resource_group.resource_group.location
  account_tier                  = "Standard"
  account_replication_type      = "GRS"
  public_network_access_enabled = false

  tags = {
    Name = "Development"
  }
}