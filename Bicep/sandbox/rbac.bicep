param ownerId string
param name string

resource rbac 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: name
  properties: {
    principalId: ownerId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  }
}
