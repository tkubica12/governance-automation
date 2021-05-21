resource "azurerm_subscription" "b2b" {
  alias             = "b2b"
  subscription_name = "B2B"
  subscription_id   = "7bead9cf-e290-4c50-8651-fcc22c9c70a5"
}

locals {
  b2bRbac = {
    "/subscriptions/${azurerm_subscription.b2b.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635" = "36fdd187-d556-4e31-9ac6-51a8b595a2a7" // user1@tomaskubica.cz as Owner
    "/subscriptions/${azurerm_subscription.b2b.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635" = "720303ea-d09e-4e49-8a21-6634b99b9a17" // L1-group as Owner
    "/subscriptions/${azurerm_subscription.b2b.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c" = "b28dec96-590c-45bd-8811-7dfb5f6fcf9b" // wvd1@tomaskubica.cz as Contributor
    "${azurerm_role_definition.limitedContributor.role_definition_resource_id}"                                                                         = "4417880f-3709-45c8-9e5d-9015438dba7d" // wvd2@tomaskubica.cz as limitedContributor
  }
}

resource "azurerm_role_assignment" "b2b" {
  for_each           = local.b2bRbac
  scope              = "/subscriptions/${azurerm_subscription.b2b.subscription_id}"
  role_definition_id = each.key
  principal_id       = each.value
}
