variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location for all resources."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random value so name is unique in your Azure subscription."
}

variable "container_group_name_prefix" {
  type        = string
  description = "Prefix of the container group name that's combined with a random value so name is unique in your Azure subscription."
  default     = "acigroup"
}

variable "container_name_prefix" {
  type        = string
  description = "Prefix of the container name that's combined with a random value so name is unique in your Azure subscription."
  default     = "aci"
}

variable "image" {
  type        = string
  description = "Container image to deploy. Should be of the form repoName/imagename:tag for images stored in public Docker Hub, or a fully qualified URI for other registries. Images from private registries require additional registry credentials."
  default     = "manuelalonsocarracedo/wilde_test:v1"
}

variable "port" {
  type        = number
  description = "Port to open on the container and the public IP address."
  default     = 5000
}

variable "cpu_cores" {
  type        = number
  description = "The number of CPU cores to allocate to the container."
  default     = 1
}

variable "memory_in_gb" {
  type        = number
  description = "The amount of memory to allocate to the container in gigabytes."
  default     = 2
}

variable "restart_policy" {
  type        = string
  description = "The behavior of Azure runtime if container has stopped."
  default     = "Always"
  validation {
    condition     = contains(["Always", "Never", "OnFailure"], var.restart_policy)
    error_message = "The restart_policy must be one of the following: Always, Never, OnFailure."
  }
}

variable "database_edition" {
  type        = string
  description = "Edition of the Azure SQL Database."
  default     = "Basic"
}

variable "database_collation" {
  type        = string
  description = "Collation setting for the Azure SQL Database."
  default     = "SQL_Latin1_General_CP1_CI_AS"
}

variable "mssql-admin" {
  type        = string
  description = "Username for the SQL Server administrator."
  default = "sqladmin"
}

variable "database_admin_password" {
  type        = string
  description = "Password for the SQL Server administrator."
  default = "P@ssw0rd1234!"
}

variable "private_dns_zone_name" {
  type        = string
  description = "Name of the private DNS zone."
  default     = "wilde"
}

variable "wilde-app-port" {
  type    = number
  default = 8081
}