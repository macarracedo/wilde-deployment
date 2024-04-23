output "container_ipv4_address" {
  value = azurerm_container_group.wilde-app-container.ip_address
}

output "database_server_name" {
  value = azurerm_mssql_server.wilde-mssql-server.name
}

output "database_name" {
  value = azurerm_mssql_database.wilde-mssql-app-db.name
}

output "wilde-app-gateway-public-ip" {
  value = azurerm_public_ip.wilde-app-gateway-public-ip.ip_address
}