param packageUrl string

var location = resourceGroup().location

resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: uniqueString(resourceGroup().id)
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: logWorkspace.name
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    WorkspaceResourceId: logWorkspace.id
  } 
}

resource functionsPlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: 'functionsPlan'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

resource functionsStorage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: uniqueString(resourceGroup().id)
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource functions 'Microsoft.Web/sites@2020-12-01' = {
  name: 'budgets${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: functionsPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'powershell'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionsStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(functionsStorage.id, functionsStorage.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: packageUrl
        }
      ]
    }
  }
}

resource actionStop 'microsoft.insights/actionGroups@2019-06-01' = {
  name: 'budgetReactionStop'
  location: 'global'
  properties: {
    groupShortName: 'budgetStop'
    enabled: true
    azureFunctionReceivers: [
      {
        name: 'function'
        functionName: 'budgetActionStop'
        functionAppResourceId: functions.id
        httpTriggerUrl: 'https://${functions.name}.azurewebsites.net/api/budgetActionStop?code=${listkeys(concat(functions.id, '/host/default'), '2016-08-01').masterKey}'
        useCommonAlertSchema: false
      }
    ]
  }
}

resource actionDelete 'microsoft.insights/actionGroups@2019-06-01' = {
  name: 'budgetReactionDelete'
  location: 'global'
  properties: {
    groupShortName: 'budgetDelete'
    enabled: true
    azureFunctionReceivers: [
      {
        name: 'function'
        functionName: 'budgetActionDelete'
        functionAppResourceId: functions.id
        httpTriggerUrl: 'https://${functions.name}.azurewebsites.net/api/budgetActionDelete?code=${listkeys(concat(functions.id, '/host/default'), '2016-08-01').masterKey}'
        useCommonAlertSchema: false
      }
    ]
  }
}

output functionsIdentityId string = functions.identity.principalId
output actionStop string = actionStop.id
output actionDelete string = actionDelete.id


