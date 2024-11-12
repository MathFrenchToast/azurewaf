
resource "azurerm_resource_group" "rg_appgw_test" {
  name     = "rg-appgw-test"
  location = var.resource_group_location
}

resource "azurerm_virtual_network" "vnet_appgw" {
  name                = "vnet-appgw-test"
  resource_group_name = azurerm_resource_group.rg_appgw_test.name
  location            = azurerm_resource_group.rg_appgw_test.location
  address_space       = ["10.250.0.0/16"]
}