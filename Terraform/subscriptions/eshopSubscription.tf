resource "azurerm_subscription" "eshop" {
  alias             = "eshop"
  subscription_name = "E-shop"
  subscription_id   = "4fd63c38-a6be-4fb1-ac9e-ab1781af69ad"
}

locals {
  eshopRbac = {
    "36fdd187-d556-4e31-9ac6-51a8b595a2a7" = "/subscriptions/${azurerm_subscription.eshop.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635" // user1@tomaskubica.cz as Owner
    "b402e595-21e4-4a80-a4aa-bff61cb035a2" = "/subscriptions/${azurerm_subscription.eshop.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635" // user2@tomaskubica.cz as Owner
    "b28dec96-590c-45bd-8811-7dfb5f6fcf9b" = "/subscriptions/${azurerm_subscription.eshop.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c" // wvd1@tomaskubica.cz as Contributor
  }
}

resource "azurerm_role_assignment" "eshop" {
  for_each           = local.eshopRbac
  scope              = "/subscriptions/${azurerm_subscription.eshop.subscription_id}"
  role_definition_id = each.value
  principal_id       = each.key
}

// Subscription-scope resources
provider "azurerm" {
  alias           = "eshop"
  subscription_id = azurerm_subscription.eshop.subscription_id
  features {}
}

// Budgets
resource "azurerm_resource_group" "eshop-budgets-rg" {
  provider = azurerm.eshop
  name     = "budgets-rg"
  location = "West Europe"
}

resource "azurerm_consumption_budget_subscription" "eshop-overall" {
  provider = azurerm.eshop
  name            = "overall"
  subscription_id = azurerm_subscription.eshop.subscription_id

  amount     = 1000
  time_grain = "Monthly"

  time_period {
    start_date = "2021-05-01T00:00:00Z"
    end_date   = "2031-12-01T00:00:00Z"
  }

  notification {
    enabled   = false
    threshold = 100.0
    operator  = "GreaterThan"

    contact_emails = [
      "foo@example.com",
      "bar@example.com",
    ]
  }
}
