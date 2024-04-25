// EXISTING RESOURCE GROUP FOR COMMON RESOURCES
data "azurerm_resource_group" "wilde-common-rg" {
  name = "wilde-common-rg"
}

// EXISTING KEY VAULT
data "azurerm_key_vault" "wilde-common-kv" {
  name                = "wilde-common-kv"
  resource_group_name = data.azurerm_resource_group.wilde-common-rg.name
}

// EXISTING BACKEND STORAGE ACCOUNT
data "azurerm_storage_account" "wildeterraformbackend" {
  name                = "wildeterraformbackend"
  resource_group_name = data.azurerm_resource_group.wilde-common-rg.name
}

// NETWORK SECURITY GROUP
resource "azurerm_network_security_group" "wilde-common-nsg" {
  name                = "wilde-common-nsg"
  location            = data.azurerm_resource_group.wilde-common-rg.location
  resource_group_name = data.azurerm_resource_group.wilde-common-rg.name
}

// VIRTUAL NETWORK
resource "azurerm_virtual_network" "wilde-common-vnet" {
  name                = "wilde-common-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.wilde-common-rg.location
  resource_group_name = data.azurerm_resource_group.wilde-common-rg.name
}

// VIRTUAL NETWORK SUBNETS
resource "azurerm_subnet" "wilde-subnets" {

  // Subnet parameters definition
  for_each = {
    "wilde-app-gateway-subnet"      = ["10.0.0.0/24"],
    "wilde-app-subnet"              = ["10.0.1.0/24"],
    "wilde-data-subnet"             = ["10.0.2.0/24"]
  }

  // Subnet parameters assignment 
  name                 = each.key
  address_prefixes     = each.value
  resource_group_name  = azurerm_virtual_network.wilde-common-vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.wilde-common-vnet.name

  // Delegation for Container Instance VNet Integration if subnet is "wilde-app-subnet"
  dynamic "delegation" {
    for_each = each.key == "wilde-app-subnet" ? toset([1]) : toset([])
    content {
      name = "delegation"
      service_delegation {
        name = "Microsoft.ContainerInstance/containerGroups"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
}

// Allow web traffic from Internet
resource "azurerm_network_security_rule" "wilde-common-nsg-rule1" {
  network_security_group_name = azurerm_network_security_group.wilde-common-nsg.name
  resource_group_name         = azurerm_network_security_group.wilde-common-nsg.resource_group_name
  name                        = "AllowWebFromInternet"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = [var.wilde-app-port,]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

// Allow incoming Internet traffic to App Gateway
resource "azurerm_network_security_rule" "wilde-common-nsg-rule2" {
  network_security_group_name = azurerm_network_security_group.wilde-common-nsg.name
  resource_group_name         = azurerm_network_security_group.wilde-common-nsg.resource_group_name
  name                        = "AllowIncomingAppGateway"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_subnet_network_security_group_association" "wilde-common-nsg-association" {
  for_each                  = azurerm_subnet.wilde-subnets
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.wilde-common-nsg.id
}

// APP GATEWAY

resource "azurerm_public_ip" "wilde-app-gateway-public-ip" {
  name                = "wilde-app-gateway-public-ip"
  sku                 = "Standard"
  location            = data.azurerm_resource_group.wilde-common-rg.location
  resource_group_name = data.azurerm_resource_group.wilde-common-rg.name
  allocation_method   = "Static"
}

resource "azurerm_application_gateway" "wilde-app-gateway" {

  // BASIC APP GATEWAY SETTINGS
  name                = "wilde-app-gateway"
  resource_group_name = data.azurerm_resource_group.wilde-common-rg.name
  location            = data.azurerm_resource_group.wilde-common-rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "wilde-app-gateway-subnet-configuration"
    subnet_id = azurerm_subnet.wilde-subnets["wilde-app-gateway-subnet"].id
  }

  frontend_ip_configuration {
    name                 = "wilde-app-gateway-frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.wilde-app-gateway-public-ip.id
  }

  // IAAS BACKEND SETTINGS (CONTAINER Instance updating)

  frontend_port {
    name = "wilde-app-gateway-app-frontend-port"
    port = var.wilde-app-port
  }

  backend_address_pool {
    name         = "wilde-app-gateway-app-backend-pool"
    ip_addresses = [azurerm_container_group.wilde-app-container.ip_address]
  }

  probe {
    name                = "wilde-app-gateway-app-probe"
    host                = "127.0.0.1"
    interval            = 10
    timeout             = 60
    unhealthy_threshold = 1
    port                = var.wilde-app-port
    protocol            = "Http"
    path                = "/"
  }

  backend_http_settings {
    name                  = "wilde-app-gateway-app-backend-http-settings"
    probe_name            = "wilde-app-gateway-app-probe"
    cookie_based_affinity = "Disabled"
    port                  = var.wilde-app-port
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = "wilde-app-gateway-app-listener"
    frontend_ip_configuration_name = "wilde-app-gateway-frontend-ip-config"
    frontend_port_name             = "wilde-app-gateway-app-frontend-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "wilde-app-gateway-app-routing-rule"
    rule_type                  = "Basic"
    priority                   = 10
    http_listener_name         = "wilde-app-gateway-app-listener"
    backend_address_pool_name  = "wilde-app-gateway-app-backend-pool"
    backend_http_settings_name = "wilde-app-gateway-app-backend-http-settings"
  }
}