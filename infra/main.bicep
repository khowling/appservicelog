param name string
var location = resourceGroup().location

// ------------------------------------ App Service Plan & WebApp --------------

resource farm 'Microsoft.Web/serverfarms@2020-09-01' = {
  name: name
  location: location
  sku: {
    name: 'P1v2'
    tier: 'PremiumV2'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource site 'Microsoft.Web/sites@2020-10-01' = {
  name: name
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: farm.id
  }
}

// ------------------------------------    Loggining Function App         --------------
param NR_LICENSE_KEY string = ''

resource fnstore 'Microsoft.Storage/storageAccounts@2021-01-01' = if (!empty(NR_LICENSE_KEY)) {
  name: name
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource fnlog 'Microsoft.Web/sites@2020-10-01' = if (!empty(NR_LICENSE_KEY)) {
  name: '${name}fnlog'
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: farm.id
    siteConfig: {
      linuxFxVersion: 'node|14'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${fnstore.name};AccountKey=${listKeys(fnstore.id, '2021-01-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'loggingHub'
          value: listKeys(ehauth.id, '2017-04-01').primaryConnectionString
        }
        {
          name: 'NR_LICENSE_KEY'
          value: NR_LICENSE_KEY
        }
      ]
    }
  }
}

// ------------------------------------      ACR and Pull Auth       --------------

resource acr 'Microsoft.ContainerRegistry/registries@2019-05-01' = {
  name: name
  location: location
  sku: {
    name: 'Basic'
  }
}
var AcrPullRole = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource aks_acr_pull 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: acr
  name: guid(resourceGroup().id, name)
  properties: {
    roleDefinitionId: AcrPullRole
    principalType: 'ServicePrincipal'
    principalId: site.identity.principalId
  }
}

// ------------------------------------ Diags to Eventhub config ---------------

resource eh 'Microsoft.EventHub/namespaces@2018-01-01-preview' = {
  name: name
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
}
resource ehhub 'Microsoft.EventHub/namespaces/eventhubs@2017-04-01' = {
  parent: eh
  name: 'logging'
  properties: {
    messageRetentionInDays: 1
  }
}
resource ehauth 'Microsoft.EventHub/namespaces/authorizationRules@2017-04-01' = {
  parent: eh
  name: 'logginauth'
  properties: {
    rights: [
      'Send'
      'Manage'
      'Listen'
    ]
  }
}

resource diag 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: site
  name: 'appservicelogging'
  properties: {
    eventHubAuthorizationRuleId: ehauth.id
    eventHubName: ehhub.name
    logs: [
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
    ]
  }
}
