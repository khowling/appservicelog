param name string
param container string
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

resource site 'Microsoft.Web/sites@2020-09-01' = {
  name: name
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: farm.id
    //siteConfig: {
    //  linuxFxVersion: 'DOCKER|${acr.properties.loginServer}/${container}'
    //  acrUseManagedIdentityCreds: true
    //}
  }
}

// ------------------------------------ ACR and Pull Auth --------------

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
