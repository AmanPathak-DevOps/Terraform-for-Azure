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
  public_network_access_enabled = true

  tags = {
    Name = "Development"
  }
}

resource "azurerm_storage_container" "container" {
    name = var.container_name
    storage_account_name = azurerm_storage_account.storage_account.name
    container_access_type = "blob"
}

resource "azurerm_storage_blob" "blob" {
    name = var.blob_name
    storage_account_name = azurerm_storage_account.storage_account.name
    storage_container_name = azurerm_storage_container.container.name
    type = "Block"
    source = var.source_file
}