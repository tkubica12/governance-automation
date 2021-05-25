targetScope = 'subscription'

param limitedContributorRole string

// Assign access control rules
var b2bRbac = [
  {
    principal: '36fdd187-d556-4e31-9ac6-51a8b595a2a7' // user1@tomaskubica.cz
    role: '/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635' // Owner
  }
  {
    principal: '720303ea-d09e-4e49-8a21-6634b99b9a17' // L1-group
    role: '/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635' // Owner
  }
  {
    principal: 'b28dec96-590c-45bd-8811-7dfb5f6fcf9b' // wvd1@tomaskubica.cz
    role: '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
  }
  {
    principal: '4417880f-3709-45c8-9e5d-9015438dba7d' // wvd2@tomaskubica.cz
    role: limitedContributorRole
  }
]

resource rbac 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for (config, i) in b2bRbac: {
  name: config.principal
  properties: {
    principalId: config.principal
    roleDefinitionId: config.role
  }
}]

resource b2bNetworkingRg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: 'networking-rg'
  location: 'westeurope'
}

resource budgetb2bOverall 'Microsoft.Consumption/budgets@2019-10-01' = {
  name: 'overall'
  properties: {
    amount: 600
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
