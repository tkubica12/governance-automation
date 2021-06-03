targetScope = 'subscription'

param packageUrl string

var location = 'westeurope'

var sandboxes = [
  {
    name: 'research1'
    ownerId: '7424fb4c-5e9f-45cd-9f7d-453d45655e75' // tokubica
    ownerEmail: 'tomas.kubica@microsoft.com'
    monthlyBudget: 100
  }
  {
    name: 'research2'
    ownerId: '7424fb4c-5e9f-45cd-9f7d-453d45655e75' // tokubica
    ownerEmail: 'tomas.kubica@microsoft.com'
    monthlyBudget: 80
  }
  {
    name: 'research3'
    ownerId: '7424fb4c-5e9f-45cd-9f7d-453d45655e75' // tokubica
    ownerEmail: 'tomas.kubica@microsoft.com'
    monthlyBudget: 5
  }
]

resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = [for (config, i) in sandboxes: {
  location: location
  name: config.name
}]

module rbac 'rbac.bicep' = [for (config, i) in sandboxes: {
  name: 'rbac-${config.name}'
  scope: rg[i]
  params: {
    name: guid(config.name)
    ownerId: config.ownerId
  }
}]

resource infraRg 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  name: 'budgets'
}

module infrastructure 'infrastructure.bicep' = {
  name: 'infrastructure'
  scope: infraRg
  params: {
    packageUrl: packageUrl
  }
}

resource functionsRbac 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid('functionsRbac')
  scope: subscription()
  properties: {
    principalId: infrastructure.outputs.functionsIdentityId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  }
}

resource budget 'Microsoft.Consumption/budgets@2019-10-01' = [for (config, i) in sandboxes:  {
  name: config.name
  properties: {
    category: 'Cost'
    amount: config.monthlyBudget
    filter: {
      dimensions: {
        name: 'ResourceGroupName'
        operator: 'In'
        values: [
          config.name
        ]
      }
    }
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: '2021-06-01T00:00:00Z'
      endDate: '2031-12-01T00:00:00Z'
    }
    notifications: {
      basicNotification: {
        enabled: true
        threshold: 80
        thresholdType: 'Actual'
        operator: 'GreaterThan'
        contactEmails: [
          config.OwnerEmail
        ]
      }  
      stop: {
        enabled: true
        threshold: 100
        thresholdType: 'Actual'
        operator: 'GreaterThan'
        contactEmails: [
          config.OwnerEmail
        ]
        contactGroups: [
          infrastructure.outputs.actionStop
        ]
      }  
      delete: {
        enabled: true
        threshold: 120
        thresholdType: 'Actual'
        operator: 'GreaterThan'
        contactEmails: [
          config.OwnerEmail
        ]
        contactGroups: [
          infrastructure.outputs.actionDelete
        ]
      }  
    }
  }
}]
