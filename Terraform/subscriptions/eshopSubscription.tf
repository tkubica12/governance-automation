resource "azurerm_subscription" "eshop" {
  alias             = "eshop"
  subscription_name = "E-shop"
  subscription_id   = "52835e25-3a32-4eb3-8e03-4851cdc189c9"
}

locals {
  eshopRbac = {
    "/subscriptions/${azurerm_subscription.eshop.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635" = "36fdd187-d556-4e31-9ac6-51a8b595a2a7" // user1@tomaskubica.cz as Owner
    "/subscriptions/${azurerm_subscription.eshop.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635" = "b402e595-21e4-4a80-a4aa-bff61cb035a2" // user2@tomaskubica.cz as Owner
    "/subscriptions/${azurerm_subscription.eshop.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c" = "b28dec96-590c-45bd-8811-7dfb5f6fcf9b" // wvd1@tomaskubica.cz as Contributor
  }
}

resource "azurerm_role_assignment" "eshop" {
  for_each           = local.eshopRbac
  scope              = "/subscriptions/${azurerm_subscription.eshop.subscription_id}"
  role_definition_id = each.key
  principal_id       = each.value
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

resource "azurerm_consumption_budget_subscription" "overall" {
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
