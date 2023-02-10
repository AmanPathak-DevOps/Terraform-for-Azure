locals {
  resource_group_name = "Resource-For-VPC"
  location            = "East US"
}

resource "azurerm_resource_group" "resource-group" {
  name     = local.resource_group_name
  location = local.location
}
resource "azurerm_virtual_network" "virtual-network" {
  name                = var.vn-Name
  resource_group_name = azurerm_resource_group.resource-group.name
  location            = azurerm_resource_group.resource-group.location
  address_space       = [var.address_vn]

  subnet {
    name           = var.subnet1
    address_prefix = var.address_subnet1
  }
  subnet {
    name           = var.subnet2
    address_prefix = var.address_subnet2
  }

  tags = {
    Environment = var.env
  }
}