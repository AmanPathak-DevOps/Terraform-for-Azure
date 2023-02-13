locals {
  resource_group_name = "Resource-For-LinuxVM"
  location            = "North Europe"
  custom_data         = <<CUSTOM_DATA
#!/bin/bash
apt update
apt upgrade
apt-get -y install net-tools nginx
cd /var/www/html
sudo wget https://www.tooplate.com/zip-templates/2106_soft_landing.zip
sudo apt install unzip
sudo unzip 2106_soft_landing.zip
sudo rm -rf 2106_soft_landing.zip index.nginx-debian.html
cd 2106_soft_landing/
sudo mv index.html ../
sudo mv css ../
sudo mv fonts ../
sudo mv images js ../
sudo rm -rf 2106_soft_landing/
CUSTOM_DATA
}

resource "azurerm_resource_group" "resource_group" {
  name     = local.resource_group_name
  location = local.location
}

resource "azurerm_virtual_network" "vn-linux" {
  name                = var.vn-name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  address_space       = [var.vn_address]

  tags = {
    Environment = var.env
  }
}

resource "azurerm_subnet" "subnet1" {
  name                 = var.subnet-name
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vn-linux.name
  address_prefixes     = [var.subnet_address]
}

resource "azurerm_network_security_group" "network-sg" {
  name                = "sg-for-linux"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  security_rule {
    name                       = "sgrule-for-linux"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range        = "*"
    destination_port_range   = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.env
  }
}

resource "azurerm_subnet_network_security_group_association" "security-association" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.network-sg.id
}

resource "azurerm_public_ip" "pub-address" {
  name                = "public-id"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-for-linux-vm"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pub-address.id
  }

  tags = {
    Environment = var.env
  }
}

resource "tls_private_key" "linux_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "local_linux" {
  filename = "linuxkey.pem"
  content  = tls_private_key.linux_key.private_key_pem
}
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = var.vm-name
  resource_group_name   = azurerm_resource_group.resource_group.name
  location              = azurerm_resource_group.resource_group.location
  size                  = "Standard_F2"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.linux_key.public_key_openssh
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  custom_data = base64encode(local.custom_data)

  depends_on = [
    tls_private_key.linux_key
  ]
}