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
    "cw-app-gateway-subnet"     = ["10.0.0.0/24"],
    "wilde-app-subnet"          = ["10.0.1.0/24"],
    "wilde-data-subnet"         = ["10.0.4.0/24"]
  }

  // Subnet parameters assignment 
  name                 = each.key
  address_prefixes     = each.value
  resource_group_name  = azurerm_virtual_network.wilde-common-vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.wilde-common-vnet.name

  // Delegation for App Service VNet Integration if subnet is "cw-paas-web-app-int-subnet"
  dynamic "delegation" {
    for_each = each.key == "cw-paas-web-app-int-subnet" ? toset([1]) : toset([])
    content {
      name = "delegation"
      service_delegation {
        name = "Microsoft.Web/serverFarms"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/action"
        ]
      }
    }
  }
}

// NETWORK SECURITY GROUP
resource "azurerm_network_security_group" "wilde-common-nsg" {
  name                = "wilde-common-nsg"
  location            = data.azurerm_resource_group.wilde-common-rg.location
  resource_group_name = data.azurerm_resource_group.wilde-common-rg.name

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