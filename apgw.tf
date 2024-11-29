# based on : https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway


# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${var.project_name_prefix}-beap"
  frontend_port_name             = "${var.project_name_prefix}-feport"
  frontend_ip_configuration_name = "${var.project_name_prefix}-feip"
  http_setting_name              = "${var.project_name_prefix}-be-htst"
  listener_name                  = "${var.project_name_prefix}-httplstn"
  request_routing_rule_name      = "${var.project_name_prefix}-rqrt"
  redirect_configuration_name    = "${var.project_name_prefix}-rdrcfg"  
  zones                          = ["1", "2"]  # test effect on cost
}

resource "azurerm_subnet" "subnet_appgw" {
  name                 = "subnet-appgw-test"
  resource_group_name  = azurerm_resource_group.rg_appgw_test.name
  virtual_network_name = azurerm_virtual_network.vnet_appgw.name
  address_prefixes     = ["10.250.0.0/24"]
}

resource "azurerm_public_ip" "pip_appgw" {
  name                = "pip_appgw"
  resource_group_name = azurerm_resource_group.rg_appgw_test.name
  location            = azurerm_resource_group.rg_appgw_test.location
  allocation_method   = "Static"
  zones = local.zones  # if appgw is zonal then the ip needs to be zonal too
  
}




resource "azurerm_application_gateway" "appgw" {
  name                = "example-appgateway"
  resource_group_name = azurerm_resource_group.rg_appgw_test.name
  location            = azurerm_resource_group.rg_appgw_test.location
  zones = local.zones

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    # capacity = 2 # not used as we defined autoscale_configuration
  }

  autoscale_configuration {
    min_capacity = 1 # 2 is the recommended minimum for production env.
    max_capacity = 10
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.subnet_appgw.id
  }

  # use a waf policy instead of the waf_configuration block
  # waf_configuration {
  #   enabled          = true
  #   firewall_mode = "Prevention"
  #   rule_set_type = "Microsoft_Default_Rule_Set"
  #   rule_set_version = "2.1"
  # }

  force_firewall_policy_association = true

  # firewall_policy_id could be set per http listener
  firewall_policy_id = azurerm_web_application_firewall_policy.waf_policy.id

  # we can add more than one frontend_port, e.g. https 443 for ssl offloading
  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip_appgw.id
  }

  # It is possible to add multiple backend pools, each with their own backend
  backend_address_pool {
    name = local.backend_address_pool_name
    ip_addresses = [azurerm_container_group.container.ip_address]

  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"    
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic" # rule_type is either 'Basic' or 'PathBasedRouting' for additional path filtering
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    # instead of a backend_http_settings_name 
    # we could use a redirect_configuration_name for redirect rules
    backend_http_settings_name = local.http_setting_name
  }
}

resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name                = "wafpolicy"
  resource_group_name = azurerm_resource_group.rg_appgw_test.name
  location            = azurerm_resource_group.rg_appgw_test.location  

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"  # use "Detection" to only alert and not block
    request_body_check          = true # see https://learn.microsoft.com/en-us/azure/web-application-firewall/shared/waf-azure-policy
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128

    # protect sensitive data in log
    log_scrubbing {
      enabled = false
      # check if default behavior is enought
    }
  }

  
  managed_rules {
    managed_rule_set {
      type    = "Microsoft_DefaultRuleSet"
      version = "2.1"     
      }

    managed_rule_set {
      type    = "Microsoft_BotManagerRuleSet"
      version = "1.0"     # 1.1 not yet supported by provider see: https://github.com/hashicorp/terraform-provider-azurerm/pull/27855
      }

      
   }
  

  ## add custom rules
  # custom_rules {    
  # }
  }

# logs config
resource "azurerm_log_analytics_workspace" "appgw_log_analytics" {
  name                = "appgw-log-analytics"
  location            = azurerm_resource_group.rg_appgw_test.location
  resource_group_name = azurerm_resource_group.rg_appgw_test.name
  sku                 = "PerGB2018"
}

resource "azurerm_monitor_diagnostic_setting" "appgw_monitor_diagnostic_setting" {
  name                       = "appgw-monitor-diagnostic-setting"
  target_resource_id         = azurerm_application_gateway.appgw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.appgw_log_analytics.id

  # enabled_log {
  #   category = "ApplicationGatewayAccessLog"
  # }
  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }
 

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
