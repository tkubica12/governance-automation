targetScope = 'tenant'

// Create Management Groups and assign subscriptions
module managementGroups 'managementGroups.bicep' = {
  name: 'managementGroups'
}

// Create or rename subscriptions
module subscriptions 'subscriptions.bicep' = {
  name: 'subscriptions'
}

// Create custom roles
module customRoles 'customRoles.bicep' = {
  name: 'customRoles'
  scope: subscription('4fd63c38-a6be-4fb1-ac9e-ab1781af69ad')
}

// Create policy initiatives for production
module policies 'policies.bicep' = {
  name: 'policies'
  scope: managementGroup('Production')
}

// E-shop subscription
module eshopSubscription 'eshopSubscription.bicep' = {
  name: 'eshopSubscription'
  scope: subscription('4fd63c38-a6be-4fb1-ac9e-ab1781af69ad')
}

// B2B subscription
module b2bSubscription 'b2bSubscription.bicep' = {
  name: 'b2bSubscription'
  scope: subscription('7bead9cf-e290-4c50-8651-fcc22c9c70a5')
  params: {
    limitedContributorRole: customRoles.outputs.limitedContributorRole
  }
}
