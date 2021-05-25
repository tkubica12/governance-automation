targetScope = 'tenant'

resource eshopSubscription 'Microsoft.Subscription/aliases@2020-09-01' = {
  name: 'eshop'
  properties: {
    subscriptionId: '4fd63c38-a6be-4fb1-ac9e-ab1781af69ad'
  }
}

resource b2bSubscription 'Microsoft.Subscription/aliases@2020-09-01' = {
  name: 'b2b'
  properties: {
    subscriptionId: '7bead9cf-e290-4c50-8651-fcc22c9c70a5'
  }
}

output eshopSubscriptionId string = eshopSubscription.properties.subscriptionId
output b2bSubscriptionId string = b2bSubscription.properties.subscriptionId
