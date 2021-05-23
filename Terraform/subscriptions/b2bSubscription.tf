resource "azurerm_subscription" "b2b" {
  alias             = "b2b"
  subscription_name = "B2B"
  subscription_id   = "7bead9cf-e290-4c50-8651-fcc22c9c70a5"
}

locals {
  b2bRbac = {
    "36fdd187-d556-4e31-9ac6-51a8b595a2a7" = "/subscriptions/${azurerm_subscription.b2b.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635" // user1@tomaskubica.cz as Owner
    "720303ea-d09e-4e49-8a21-6634b99b9a17" = "/subscriptions/${azurerm_subscription.b2b.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635" // L1-group as Owner
    "b28dec96-590c-45bd-8811-7dfb5f6fcf9b" = "/subscriptions/${azurerm_subscription.b2b.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c" // wvd1@tomaskubica.cz as Contributor
    "4417880f-3709-45c8-9e5d-9015438dba7d" = "${azurerm_role_definition.limitedContributor.role_definition_resource_id}"                                                                         // wvd2@tomaskubica.cz as limitedContributor
  }
}

resource "azurerm_role_assignment" "b2b" {
  for_each           = local.b2bRbac
  scope              = "/subscriptions/${azurerm_subscription.b2b.subscription_id}"
  role_definition_id = each.value
  principal_id       = each.key
}

// Subscription-scope resources
provider "azurerm" {
  alias           = "b2b"
  subscription_id = azurerm_subscription.b2b.subscription_id
  features {}
}

// Budgets
resource "azurerm_resource_group" "b2b-budgets-rg" {
  provider = azurerm.b2b
  name     = "budgets-rg"
  location = "West Europe"
}

resource "azurerm_consumption_budget_subscription" "b2b-overall" {
  provider = azurerm.b2b
  name            = "overall"
  subscription_id = azurerm_subscription.b2b.subscription_id

  amount     = 600
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
