locals {
  sqlalchemy_connection_string_1 = "mssql+pyodbc://${var.mssql-admin}:${var.mssql-admin-pass}@${azurerm_mssql_server.wilde-mssql-server.fully_qualified_domain_name}/${azurerm_mssql_database.wilde-mssql-app-db.name}?driver=ODBC+Driver+18+for+SQL+Server&trustServerCertificate=no"
}

locals {
  sqlalchemy_connection_string_2 = "mssql+pymssql://${var.mssql-admin}:${var.mssql-admin-pass}@${azurerm_mssql_server.wilde-mssql-server.fully_qualified_domain_name}/${azurerm_mssql_database.wilde-mssql-app-db.name}?charset=utf8"
}