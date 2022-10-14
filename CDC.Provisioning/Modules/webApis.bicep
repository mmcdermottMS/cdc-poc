param location string
param resourcePrefix string
param appServicePlanSku object
param webAppNames array
param aseId string
param zoneRedundant bool

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: '${resourcePrefix}-asp-webApps'
  kind: 'linux'
  location: location
  sku: appServicePlanSku
  properties: {
    hostingEnvironmentProfile: {
      id: aseId
    }
    zoneRedundant: zoneRedundant
  }
}

resource functionApps 'Microsoft.Web/sites@2021-03-01' = [for webAppName in webAppNames:{
  name: '${resourcePrefix}-as-${webAppName}'
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
}]
