# AppGateway with WAF terrforming

Terraforming of an Azure WAF with:=
- extensible WAF policy
- default microsoft and bot ruleset
- logs enable

Here a private ACI hosting an helloworld web app is used to illustrate the AppGateway frontend to backend pull.
A VNET and 2 subnet are created:
- first for the appgw itself, 
- second for the aci (with delegation)

To search in logs: 
https://learn.microsoft.com/en-us/azure/application-gateway/log-analytics
https://learn.microsoft.com/en-us/azure/web-application-firewall/ag/log-analytics
e.g.
```
AzureDiagnostics 
| where ResourceProvider == "MICROSOFT.NETWORK" and Category == "ApplicationGatewayFirewallLog"
| limit 10
```

## todo

links:
- [Démarrage rapide : diriger le trafic web avec Azure Application Gateway – Terraform - Azure Application Gateway | Microsoft Learn](https://learn.microsoft.com/fr-fr/azure/application-gateway/quick-create-terraform)
- [Dancing with Qubits - Dancing with Qubits PDF.pdf](file:///C:/Users/mathi/Downloads/Dancing%20with%20Qubits%20PDF.pdf)
- [Démarrage rapide : créer une instance de conteneur Azure avec une adresse IP publique à l’aide de Terraform - Azure Container Instances | Microsoft Learn](https://learn.microsoft.com/fr-fr/azure/container-instances/container-instances-quickstart-terraform)
- [azurerm_application_gateway | Resources | hashicorp/azurerm | Terraform | Terraform Registry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway#ip_addresses-2)
- [azurerm_container_group | Resources | hashicorp/azurerm | Terraform | Terraform Registry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_group)
- [Protect Azure Container Apps with Application Gateway and Web Application Firewall (WAF) | Microsoft Learn](https://learn.microsoft.com/en-us/azure/container-apps/waf-app-gateway?tabs=default-domain)
- [Application gateway components | Microsoft Learn](https://learn.microsoft.com/en-us/azure/application-gateway/application-gateway-components)
- [Support for multiple frontends and backends in Azure Application Gateway · Issue #5697 · hashicorp/terraform-provider-azurerm](https://github.com/hashicorp/terraform-provider-azurerm/issues/5697)
- [AzureRM_Subnet is missing some service_delegation types · Issue #18640 · hashicorp/terraform-provider-azurerm](https://github.com/hashicorp/terraform-provider-azurerm/issues/18640)
- [azurerm_subnet | Resources | hashicorp/azurerm | Terraform | Terraform Registry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet)
- [Azure Application Gateway WAF config vs WAF policy · Coffee with Ana in the 🌩️](https://coffeewithana.cloud/posts/azure-waf-configurations/)
- [azurerm_web_application_firewall_policy | Resources | hashicorp/azurerm | Terraform | Terraform Registry](https://registry.terraform.io/providers/hashicorp/Azurerm/latest/docs/resources/web_application_firewall_policy)
