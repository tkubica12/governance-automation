targetScope = 'subscription'

var allSubscriptions = [
  '/subscriptions/4fd63c38-a6be-4fb1-ac9e-ab1781af69ad'
  '/subscriptions/7bead9cf-e290-4c50-8651-fcc22c9c70a5'
]

resource roleLimitedContributor 'Microsoft.Authorization/roleDefinitions@2018-07-01' = {
  name: guid('limitedContributor')
  properties: {
    description: 'Limited Contributor role with no permissions to manipulate route tables'
    roleName: 'limitedContributor'
    permissions: [
      {
        actions: [
          '*'
        ]
        notActions: [
          'Microsoft.Authorization/*/Delete'
          'Microsoft.Authorization/*/Write'
          'Microsoft.Authorization/elevateAccess/Action'
          'Microsoft.Blueprint/blueprintAssignments/write'
          'Microsoft.Blueprint/blueprintAssignments/delete'
          'Microsoft.Compute/galleries/share/action'
          'Microsoft.Network/routeTables/write'
          'Microsoft.Network/routeTables/join/action'
          'Microsoft.Network/routeTables/delete'
        ]
      }
    ]
    assignableScopes: allSubscriptions
  }
}

output limitedContributorRole string = roleLimitedContributor.id
