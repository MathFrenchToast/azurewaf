resource "random_string" "container_name" {
  length  = 25
  lower   = true
  upper   = false
  special = false
}

resource "azurerm_subnet" "subnet_aci" {
  name                 = "subnet-appgw-aci"
  resource_group_name  = azurerm_resource_group.rg_appgw_test.name
  virtual_network_name = azurerm_virtual_network.vnet_appgw.name
  address_prefixes     = ["10.250.1.0/24"]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
}

resource "azurerm_container_group" "container" {
  name                = "acg-${var.project_name_prefix}-${random_string.container_name.result}"
  location            = azurerm_resource_group.rg_appgw_test.location
  resource_group_name = azurerm_resource_group.rg_appgw_test.name
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.subnet_aci.id]
  os_type             = "Linux"
  restart_policy      = var.restart_policy

  container {
    name   = "acg-${var.project_name_prefix}-${random_string.container_name.result}"
    image  = var.image
    cpu    = var.cpu_cores
    memory = var.memory_in_gb

    ports {
      port     = var.port
      protocol = "TCP"
    }
  }
}
