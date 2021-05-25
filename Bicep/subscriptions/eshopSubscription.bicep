targetScope = 'subscription'

// Assign access control rules
var eshopRbac = [
  {
    principal: '36fdd187-d556-4e31-9ac6-51a8b595a2a7' // user1@tomaskubica.cz
    role: '/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635' // Owner
  }
  {
    principal: 'b402e595-21e4-4a80-a4aa-bff61cb035a2' // user2@tomaskubica.cz
    role: '/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635' // Owner
  }
  {
    principal: 'b28dec96-590c-45bd-8811-7dfb5f6fcf9b' // wvd1@tomaskubica.cz
    role: '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
  }
]

resource rbac 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for (config, i) in eshopRbac: {
  name: config.principal
  properties: {
    principalId: config.principal
    roleDefinitionId: config.role
  }
}]

resource eshopNetworkingRg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: 'networking-rg'
  location: 'westeurope'
}

resource budgetEshopOverall 'Microsoft.Consumption/budgets@2019-10-01' = {
  name: 'overall'
  properties: {
    amount: 1000
    timeGrain: 'Monthly' 
    category: 'Cost'
    timePeriod: {
      startDate: '2021-05-01T00:00:00Z'
      endDate: '2031-12-01T00:00:00Z'
    }
    notifications: {
       basicNotification: {
         enabled: true
         threshold: 100
         thresholdType: 'Actual'
         operator: 'GreaterThan'
         contactEmails: [
          'foo@example.com'
          'bar@example.com'
         ]
       }   
    }
  }
}
