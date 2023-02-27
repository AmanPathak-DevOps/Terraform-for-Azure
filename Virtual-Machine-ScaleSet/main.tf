locals {
  resource_group_name = "RG-VM-ScaleSet"
  location            = "Japan East"
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
sudo apt-get install stress
sudo stress --cpu 8 -v --timeout 30s
CUSTOM_DATA
}

resource "azurerm_resource_group" "RG-VMSet" {
  name     = local.resource_group_name
  location = local.location
}

resource "azurerm_virtual_network" "VN-VMSet" {
  name                = "VN-VMSet"
  resource_group_name = local.resource_group_name
  location            = local.location
  address_space       = ["192.168.0.0/16"]

  depends_on = [
    azurerm_resource_group.RG-VMSet
  ]
}

resource "azurerm_subnet" "Subnet-VMSet" {
  name                 = "Subnet-VMSet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.VN-VMSet.name
  address_prefixes     = ["192.168.1.0/24"]

  depends_on = [
    azurerm_virtual_network.VN-VMSet
  ]
}

resource "azurerm_public_ip" "Public-VMSet" {
  name                = "Public-VMSet"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "LB-VMSet" {
  name                = "LB-VMSet"
  resource_group_name = local.resource_group_name
  location            = local.location
  sku                 = "Standard"
  sku_tier            = "Regional"

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.Public-VMSet.id
  }

  depends_on = [
    azurerm_public_ip.Public-VMSet
  ]
}

resource "azurerm_lb_backend_address_pool" "LB-Backend" {
  loadbalancer_id = azurerm_lb.LB-VMSet.id
  name            = "ScaleSet"

  depends_on = [
    azurerm_lb.LB-VMSet
  ]
}

resource "azurerm_lb_probe" "lb-probe" {
  name            = "lb-probe"
  loadbalancer_id = azurerm_lb.LB-VMSet.id
  protocol        = "Tcp"
  port            = 80

  depends_on = [
    azurerm_lb.LB-VMSet
  ]
}

resource "azurerm_lb_rule" "lb-rule" {
  loadbalancer_id                = azurerm_lb.LB-VMSet.id
  name                           = "lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.LB-Backend.id]
}


resource "azurerm_linux_virtual_machine_scale_set" "VM-VMSet" {
  name                            = "VM-VMSet"
  resource_group_name             = local.resource_group_name
  location                        = local.location
  sku                             = "Standard_F2"
  instances                       = 1
  admin_username                  = "newroot"
  admin_password                  = "newroot@123"
  disable_password_authentication = false
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  network_interface {
    name    = "the-new-one"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.Subnet-VMSet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.LB-Backend.id]
    }
  }

  upgrade_mode = "Automatic"


  custom_data = base64encode(local.custom_data)

  depends_on = [
    azurerm_lb.LB-VMSet
  ]
}

resource "azurerm_network_security_group" "SG-VMSet" {
  name                = "SG-VMSet"
  location            = local.location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "Port22"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Port80"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  depends_on = [
    azurerm_virtual_network.VN-VMSet
  ]
}

resource "azurerm_subnet_network_security_group_association" "Subnet-NSG-VMSet" {
  subnet_id                 = azurerm_subnet.Subnet-VMSet.id
  network_security_group_id = azurerm_network_security_group.SG-VMSet.id

  depends_on = [
    azurerm_subnet.Subnet-VMSet, azurerm_network_security_group.SG-VMSet
  ]
}