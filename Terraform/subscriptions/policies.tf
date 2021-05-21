// Create company innitiative
data "azurerm_client_config" "current" {
}

resource "azurerm_policy_set_definition" "companyPolicy" {
  name                  = "companyPolicy"
  policy_type           = "Custom"
  display_name          = "Example company policy"
  management_group_name = data.azurerm_client_config.current.tenant_id

  policy_definition_reference {   // Inherit a tag from the resource group
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54"  
    reference_id         = "inherit-owner"
    parameter_values = <<PARAMETERS
    {
    "tagName": {
        "value": "owner"
        }
    }
PARAMETERS
  }

  policy_definition_reference {   // Add a tag to resource groups
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/726aca4c-86e9-4b04-b0c5-073027359532"  
    reference_id         = "write-class-unknown"
    parameter_values = <<PARAMETERS
    {
    "tagName": {
        "value": "class"
        },
    "tagValue": {
        "value": "unknown"
        }
    }
PARAMETERS
  }

}
