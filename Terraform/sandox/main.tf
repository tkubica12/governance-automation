terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

// Resource Group
resource "azurerm_resource_group" "loop" {
  for_each = local.sandboxes
  name     = each.key
  location = "West Europe"
  tags = {
    "Owner" = each.value.ownerEmail
  }
}

// RBAC
data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "loop" {
  for_each           = local.sandboxes
  scope              = azurerm_resource_group.loop[each.key].id
  role_definition_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635" // Owner
  principal_id       = each.value.ownerId
}

// Action group
// Get authentication token for Function Apps
data "azurerm_function_app_host_keys" "budget" {
  name                = azurerm_function_app.budgets.name
  resource_group_name = azurerm_function_app.budgets.resource_group_name
}

// Create Action Groups for stop and delete
resource "azurerm_monitor_action_group" "stop" {
  name                = "budgetReactionStop"
  resource_group_name = azurerm_resource_group.budgets.name
  short_name          = "budgetStop"

  azure_function_receiver {
    name                     = "function"
    function_app_resource_id = azurerm_function_app.budgets.id
    function_name            = "budgetActionStop"
    http_trigger_url         = "https://${azurerm_function_app.budgets.name}.azurewebsites.net/api/budgetActionStop?code=${data.azurerm_function_app_host_keys.budget.master_key}"
    use_common_alert_schema  = false
  }
}

resource "azurerm_monitor_action_group" "delete" {
  name                = "budgetReactionDelete"
  resource_group_name = azurerm_resource_group.budgets.name
  short_name          = "budgetDelete"

  azure_function_receiver {
    name                     = "function"
    function_app_resource_id = azurerm_function_app.budgets.id
    function_name            = "budgetActionDelete"
    http_trigger_url         = "https://${azurerm_function_app.budgets.name}.azurewebsites.net/api/budgetActionDelete?code=${data.azurerm_function_app_host_keys.budget.master_key}"
    use_common_alert_schema  = false
  }
}


// Budget
resource "azurerm_consumption_budget_subscription" "loop" {
  for_each        = local.sandboxes
  name            = each.key
  subscription_id = data.azurerm_subscription.current.subscription_id

  amount     = each.value.monthlyBudget
  time_grain = "Monthly"

  filter {
    dimension {
      name = "ResourceGroupName"
      values = [
        each.key,
      ]
    }
  }

  lifecycle {
    ignore_changes = [
      time_period["start_date"]
    ]
  }

  time_period {
    start_date = "${formatdate("YYYY-MM", timestamp())}-01T00:00:00Z"
    end_date   = "2031-12-01T00:00:00Z"
  }

  notification {
    enabled   = true
    threshold = 80.0
    operator  = "EqualTo"

    contact_roles = [
      "Owner",
    ]
  }

  notification {
    enabled   = true
    threshold = 100.0
    operator  = "EqualTo"

    contact_groups = [
      azurerm_monitor_action_group.stop.id,
    ]

    contact_roles = [
      "Owner",
    ]
  }

  notification {
    enabled   = true
    threshold = 120.0
    operator  = "EqualTo"

    contact_groups = [
      azurerm_monitor_action_group.delete.id,
    ]

    contact_roles = [
      "Owner",
    ]
  }

}
