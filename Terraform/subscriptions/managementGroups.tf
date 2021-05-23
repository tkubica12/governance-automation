resource "azurerm_management_group" "production" {
  display_name = "Production"
}

resource "azurerm_management_group" "non-production" {
  display_name = "Non-production"
}

resource "azurerm_management_group" "sandbox" {
  display_name               = "Sandbox"
  parent_management_group_id = azurerm_management_group.non-production.id

  subscription_ids = [
    # "4fd63c38-a6be-4fb1-ac9e-ab1781af69ad"
  ]
}

resource "azurerm_management_group" "ecommerce-mg" {
  display_name               = "E-commerce"
  parent_management_group_id = azurerm_management_group.production.id

  subscription_ids = [
    "4fd63c38-a6be-4fb1-ac9e-ab1781af69ad",
    "7bead9cf-e290-4c50-8651-fcc22c9c70a5"
  ]
}

// Assign policies
resource "azurerm_policy_assignment" "production-mg-policy" {
  name                 = "companyPolicyOnProdMG"
  scope                = azurerm_management_group.production.id
  policy_definition_id = azurerm_policy_set_definition.companyPolicy.id
  description          = "Company policy for production"
  display_name         = "Company policy for production"
  location             = "westeurope"
  identity { type = "SystemAssigned" }
}
