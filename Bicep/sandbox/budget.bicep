param name string
param amount int
param start string
param ownerEmail string
param actionStop string
param actionDelete string

resource budget 'Microsoft.Consumption/budgets@2019-10-01' = {
  name: name
  properties: {
    category: 'Cost'
    amount: amount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: start
      endDate: '2031-12-01T00:00:00Z'
    }
    notifications: {
      basicNotification: {
        enabled: true
        threshold: 80
        thresholdType: 'Actual'
        operator: 'GreaterThan'
        contactEmails: [
          ownerEmail
        ]
      }  
      stop: {
        enabled: true
        threshold: 100
        thresholdType: 'Actual'
        operator: 'GreaterThan'
        contactEmails: [
          ownerEmail
        ]
        contactGroups: [
          actionStop
        ]
      }  
      delete: {
        enabled: true
        threshold: 120
        thresholdType: 'Actual'
        operator: 'GreaterThan'
        contactEmails: [
          ownerEmail
        ]
        contactGroups: [
          actionDelete
        ]
      }  
    }
  }
}
