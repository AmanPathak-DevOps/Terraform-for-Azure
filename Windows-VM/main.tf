locals {
  resource_group_name = "RG-for-Windows-VM"
  location            = "North Europe"
}

resource "azurerm_resource_group" "resource-group" {
  name     = local.resource_group_name
  location = local.location
}

resource "azurerm_virtual_network" "vn" {
  name                = var.vn-name
  resource_group_name = azurerm_resource_group.resource-group.name
  location            = azurerm_resource_group.resource-group.location
  address_space       = [var.address-vn]

  tags = {
    Environment = var.env
  }
}

resource "azurerm_subnet" "subnet1" {
  name                 = var.subnet1
  resource_group_name  = azurerm_resource_group.resource-group.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = [var.subnet-address]
}

resource "azurerm_network_security_group" "network-sg" {
  name                = var.sg-name
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name

  security_rule {
    name                       = "window-rdp-connection"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.env
  }
}

resource "azurerm_subnet_network_security_group_association" "security_group_subnet_association" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.network-sg.id
}

resource "azurerm_public_ip" "public-ip" {
  name                = "public-ip"
  resource_group_name = azurerm_resource_group.resource-group.name
  location            = azurerm_resource_group.resource-group.location
  allocation_method   = "Dynamic"
}
resource "azurerm_network_interface" "nic" {
  name                = var.nic-name
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name


  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public-ip.id
  }

  tags = {
    Environment = var.env
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = var.vm-name
  resource_group_name   = azurerm_resource_group.resource-group.name
  location              = azurerm_resource_group.resource-group.location
  size                  = "Standard_F2"
  availability_set_id   = azurerm_availability_set.az-set.id
  admin_username        = var.usrname
  admin_password        = var.passwd
  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  tags = {
    Environment = var.env
  }
}

resource "azurerm_managed_disk" "data_disk" {
  name                 = "data-disk"
  location             = local.location
  resource_group_name  = local.resource_group_name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1000

}

resource "azurerm_virtual_machine_data_disk_attachment" "dd-attachment" {
  managed_disk_id    = azurerm_managed_disk.data_disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  lun                = "0"
  caching            = "ReadWrite"
}

resource "azurerm_availability_set" "az-set" {
  name                         = "az-for-windows"
  resource_group_name          = local.resource_group_name
  location                     = local.location
  platform_fault_domain_count  = 2
  platform_update_domain_count = 3
}


# Create Storage Account
resource "azurerm_storage_account" "storage-account" {
  name                          = "storageacforiisserver"
  resource_group_name           = local.resource_group_name
  location                      = local.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  public_network_access_enabled = true
  depends_on = [
    azurerm_resource_group.resource-group
  ]
}
# Create Container 
resource "azurerm_storage_container" "data-iis" {
  name                  = "data-iis"
  storage_account_name  = azurerm_storage_account.storage-account.name
  container_access_type = "blob"

  depends_on = [
    azurerm_storage_account.storage-account
  ]
}

# Create CustomScriptExtension for Windows VM and configured rest of the things
resource "azurerm_storage_blob" "IIS_config" {
  name                   = "IIS_Config.ps1"
  storage_account_name   = azurerm_storage_account.storage-account.name
  storage_container_name = "data-iis"
  type                   = "Block"
  source                 = "IIS_Config.ps1"

  depends_on = [
    azurerm_storage_container.data-iis
  ]
}

resource "azurerm_virtual_machine_extension" "vm-extension" {
  name                 = "iis-extension"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.0"

  settings = <<SETTINGS
    {
        "fileUris": ["https://${azurerm_storage_account.storage-account.name}.blob.core.windows.net/data-iis/IIS_Config.ps1"],
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file IIS_Config.ps1"     
    }
SETTINGS

  depends_on = [
    azurerm_storage_blob.IIS_config
  ]
}