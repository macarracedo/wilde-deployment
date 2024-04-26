resource "azurerm_resource_group" "wilde-app-rg" {
  name     = "wilde-app-rg"
  location = var.resource_group_location
}

resource "azurerm_network_profile" "wilde-app-network-profile" {
  name                = "wilde-app-network-profile"
  resource_group_name = azurerm_resource_group.wilde-app-rg.name
  location            = azurerm_resource_group.wilde-app-rg.location

  container_network_interface {
    name = "acg-nic"

    ip_configuration {
      name      = "aci-ipconfig"
      subnet_id = azurerm_subnet.wilde-subnets["wilde-app-subnet"].id
    }
}
}

resource "random_string" "container_name" {
  length  = 8
  lower   = true
  upper   = false
  special = false
}

resource "azurerm_container_group" "wilde-app-container" {
  name                = "${var.container_group_name_prefix}-${random_string.container_name.result}"
  location            = azurerm_resource_group.wilde-app-rg.location
  resource_group_name = azurerm_resource_group.wilde-app-rg.name
  os_type             = "Linux"
  restart_policy      = var.restart_policy
  network_profile_id  = azurerm_network_profile.wilde-app-network-profile.id
  ip_address_type     = "Private"
  #subnet_ids          = [azurerm_subnet.wilde-subnets["wilde-app-subnet"].id,]

  container {
    name   = "${var.container_name_prefix}-${random_string.container_name.result}"
    image  = var.image
    cpu    = var.cpu_cores
    memory = var.memory_in_gb
    environment_variables = {
      "DB_CONNECTION_STRING" = local.sqlalchemy_connection_string_2 # 1: pydbc connection string | 2: pymssql connection string
    }

    ports {
      port     = var.wilde-app-port
      protocol = "TCP"
    }
  }
}