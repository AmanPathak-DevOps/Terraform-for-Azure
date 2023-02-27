locals {
  resource_group_name = "RG-for-SQL-Database"
  location            = "North Europe"
}

resource "azurerm_resource_group" "RG-for-SQL" {
  name     = local.resource_group_name
  location = local.location
}

resource "azurerm_mssql_server" "sql_server" {
  name                         = "app-backend-server"
  resource_group_name          = local.resource_group_name
  location                     = local.location
  version                      = "12.0"
  administrator_login          = "newroot"
  administrator_login_password = "4-v3ry-53cr37-p455w0rd@123"
  
  depends_on = [
    azurerm_resource_group.RG-for-SQL
  ]
}

resource "azurerm_mssql_database" "sql_db" {
  name           = "app-backend-db"
  server_id      = azurerm_mssql_server.sql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 1
  sku_name       = "S0"

  depends_on = [
    azurerm_mssql_server.sql_server
  ]
}

resource "azurerm_mssql_firewall_rule" "fw_Rule-for_sql" {
  name                = "firewall-rule-sql"
  server_id           = azurerm_mssql_server.sql_server.id
  start_ip_address    = "115.110.237.74"
  end_ip_address      = "115.110.237.74"

  depends_on = [
    azurerm_mssql_database.sql_db
  ]
}