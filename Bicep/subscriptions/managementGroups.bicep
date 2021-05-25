targetScope = 'tenant'

resource mgProduction 'Microsoft.Management/managementGroups@2020-05-01' = {
  name: 'Production'
}

resource mgNonProduction 'Microsoft.Management/managementGroups@2020-05-01' = {
  name: 'Non-production'
}

resource mgSandbox 'Microsoft.Management/managementGroups@2020-05-01' = {
  name: 'Sandbox'
  properties: {
    details: {
      parent: {
        id: mgNonProduction.id
      }
    }
  }
}

resource mgEcommerce 'Microsoft.Management/managementGroups@2020-05-01' = {
  name: 'E-commerce'
  properties: {
    details: {
      parent: {
        id: mgProduction.id
      }
    }
  }
}

resource mgSubEshop 'Microsoft.Management/managementGroups/subscriptions@2020-05-01' = {
  parent: mgEcommerce
  name: '4fd63c38-a6be-4fb1-ac9e-ab1781af69ad'
}

resource mgSubB2b 'Microsoft.Management/managementGroups/subscriptions@2020-05-01' = {
  parent: mgEcommerce
  name: '7bead9cf-e290-4c50-8651-fcc22c9c70a5'
}

// Assign access control rules
var prodMgRbac = [
  {
    principal: 'cd640ddd-1ca3-4a91-8255-e8c3553bf112' // L2-group
    role: '/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635' // Owner
  }
]

resource rbac 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for (config, i) in prodMgRbac: {
  name: config.principal
  properties: {
    principalId: config.principal
    roleDefinitionId: config.role
  }
}]
