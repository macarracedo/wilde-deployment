resource "azurerm_resource_group" "wilde-app-rg" {
  name     = "wilde-app-rg"
  location = var.resource_group_location
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
  ip_address_type     = "Public"
  os_type             = "Linux"
  restart_policy      = var.restart_policy

  container {
    name   = "${var.container_name_prefix}-${random_string.container_name.result}"
    image  = var.image
    cpu    = var.cpu_cores
    memory = var.memory_in_gb

    ports {
      port     = var.port
      protocol = "TCP"
    }
  }
}

// PRIVATE NETWORKING 

resource "azurerm_private_dns_zone" "wilde-app-container-dns-zone" {
  name                = "${var.private_dns_zone_name}.azurewebsites.net"
  resource_group_name = azurerm_resource_group.wilde-app-rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "wilde-app-container-dns-zone-link" {
  name                  = "wilde-app-container-dns-zone-link"
  resource_group_name   = azurerm_resource_group.wilde-app-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.wilde-app-container-dns-zone.name
  virtual_network_id    = azurerm_virtual_network.wilde-common-vnet.id
}

module "wilde-app-container-endpoint" {
  source                             = "./tf_modules/private_endpoint"
  location                           = azurerm_resource_group.wilde-app-rg.location
  resource_group_name                = azurerm_resource_group.wilde-app-rg.name
  private_link_enabled_resource_name = azurerm_container_group.wilde-app-container.name
  private_link_enabled_resource_id   = azurerm_container_group.wilde-app-container.id
  subnet_id                          = azurerm_subnet.wilde-subnets["wilde-app-subnet"].id
  subresource_names                  = ["sites"]
  private_dns_zone_id                = azurerm_private_dns_zone.wilde-app-container-dns-zone.id
}