resource "azurerm_management_group" "production" {
  display_name = "Production"
  id           = "Production"
}

resource "azurerm_management_group" "non-production" {
  display_name = "Non-production"
  id           = "Non-production"
}

resource "azurerm_management_group" "sandbox" {
  display_name               = "Sandbox"
  id                         = "Sandbox"
  parent_management_group_id = azurerm_management_group.non-production.id

  subscription_ids = [
    # "4fd63c38-a6be-4fb1-ac9e-ab1781af69ad"
  ]
}

resource "azurerm_management_group" "ecommerce-mg" {
  display_name               = "E-commerce"
  id                         = "E-commerce"
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

// Assign access control rules
locals {
  prodMgRbac = {
    "cd640ddd-1ca3-4a91-8255-e8c3553bf112" = "/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635" // L2-group as Owner
  }
}

resource "azurerm_role_assignment" "prodMg" {
  for_each           = local.prodMgRbac
  scope              = azurerm_management_group.production.id
  role_definition_id = each.value
  principal_id       = each.key
}

