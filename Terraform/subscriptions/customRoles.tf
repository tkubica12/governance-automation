// Get all subscriptions to be used as assignable scope
data "azurerm_subscriptions" "available" {
}

data "azurerm_subscription" "main" {
  subscription_id = "52835e25-3a32-4eb3-8e03-4851cdc189c9"
}

// limitedContributor role
resource "azurerm_role_definition" "limitedContributor" {
  name        = "limitedContributor"
  scope       = data.azurerm_subscription.main.id
  description = "Limited Contributor role with no permissions to manipulate route tables"

  permissions {
    actions = ["*"]
    not_actions = [
      "Microsoft.Authorization/*/Delete",
      "Microsoft.Authorization/*/Write",
      "Microsoft.Authorization/elevateAccess/Action",
      "Microsoft.Blueprint/blueprintAssignments/write",
      "Microsoft.Blueprint/blueprintAssignments/delete",
      "Microsoft.Compute/galleries/share/action",
      "Microsoft.Network/routeTables/write",
      "Microsoft.Network/routeTables/join/action",
      "Microsoft.Network/routeTables/delete"
    ]
  }

  assignable_scopes = data.azurerm_subscriptions.available.subscriptions[*].id
}
