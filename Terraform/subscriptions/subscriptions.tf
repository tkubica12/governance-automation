// Name subscription (if you ommit subscription id this creates subscription also)
resource "azurerm_subscription" "eshop" {
  alias             = "eshop"
  subscription_name = "demo-E-shop"
  subscription_id   = "4fd63c38-a6be-4fb1-ac9e-ab1781af69ad"
}

resource "azurerm_subscription" "b2b" {
  alias             = "b2b"
  subscription_name = "demo-B2B"
  subscription_id   = "7bead9cf-e290-4c50-8651-fcc22c9c70a5"
}
