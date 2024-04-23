resource "azurerm_resource_group" "wilde-data-rg" {
  name     = "wilde-data-rg"
  location = var.resource_group_location
}

resource "azurerm_mssql_server" "wilde-mssql-server" {
  name                         = "wilde-mssql-server"
  resource_group_name          = azurerm_resource_group.wilde-data-rg.name
  location                     = azurerm_resource_group.wilde-data-rg.location
  version                      = "12.0"
  minimum_tls_version          = "1.2"

  // SQL Administrator
  administrator_login          = var.mssql-admin
  administrator_login_password = data.azurerm_key_vault_secret.db-secret.value

}

data "azurerm_key_vault_secret" "db-secret" {
  name         = "db-secret"
  key_vault_id = data.azurerm_key_vault.wilde-common-kv.id
}

resource "azurerm_mssql_database" "wilde-mssql-app-db" {
  name                = "wilde-mssql-app-db"
  server_id           = azurerm_mssql_server.wilde-mssql-server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  sku_name       = "Basic"
  max_size_gb    = 2
}

// PRIVATE NETWORKING 

resource "azurerm_private_dns_zone" "wilde-data-dns-zone" {
  name                = "${var.private_dns_zone_name}.database.windows.net"
  resource_group_name = azurerm_resource_group.wilde-data-rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "wilde-data-dns-zone-link" {
  name                  = "wilde-data-dns-zone-link"
  resource_group_name   = azurerm_resource_group.wilde-data-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.wilde-data-dns-zone.name
  virtual_network_id    = azurerm_virtual_network.wilde-common-vnet.id
}

module "wilde-mssql-server-endpoint" {
  source                             = "./tf_modules/private_endpoint"
  location                           = azurerm_resource_group.wilde-data-rg.location
  resource_group_name                = azurerm_resource_group.wilde-data-rg.name
  private_link_enabled_resource_name = azurerm_mssql_server.wilde-mssql-server.name
  private_link_enabled_resource_id   = azurerm_mssql_server.wilde-mssql-server.id
  subnet_id                          = azurerm_subnet.wilde-subnets["wilde-data-subnet"].id
  subresource_names                  = ["sqlServer"]
  private_dns_zone_id                = azurerm_private_dns_zone.wilde-data-dns-zone.id
}