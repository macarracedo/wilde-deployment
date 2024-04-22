resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  name     = random_pet.rg_name.id
  location = var.resource_group_location
}

resource "random_string" "container_name" {
  length  = 25
  lower   = true
  upper   = false
  special = false
}

/**
 * Creates an Azure Container Group.
 *
 * This resource provisions an Azure Container Group in the specified resource group and location.
 * The container group runs a single container with the specified image, CPU and memory settings.
 * It exposes a single port for inbound traffic.
 *
 * @resource {azurerm_container_group} container
 * @param {string} name - The name of the container group.
 * @param {string} location - The location where the container group will be created.
 * @param {string} resource_group_name - The name of the resource group where the container group will be created.
 * @param {string} ip_address_type - The type of IP address to allocate for the container group. (Public or Private)
 * @param {string} os_type - The operating system type of the container group. (Linux or Windows)
 * @param {string} restart_policy - The restart policy for the container group. (Always, OnFailure, or Never)
 * @param {object} container - The container configuration.
 *   @param {string} name - The name of the container.
 *   @param {string} image - The container image to run.
 *   @param {number} cpu - The number of CPU cores to allocate for the container.
 *   @param {number} memory - The amount of memory in GB to allocate for the container.
 *   @param {object} ports - The port configuration.
 *     @param {number} port - The port number to expose.
 *     @param {string} protocol - The protocol to use for the port. (TCP or UDP)
 */
resource "azurerm_container_group" "container" {
  name                = "${var.container_group_name_prefix}-${random_string.container_name.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
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