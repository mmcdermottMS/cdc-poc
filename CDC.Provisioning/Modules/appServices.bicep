param location string
param resourcePrefix string
param appServiceNameSuffix string
param zoneRedundant bool
param appServiceSubnetId string
param dockerImageAndTag string

resource asAppServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: '${resourcePrefix}-asp-${appServiceNameSuffix}'
  kind: 'app'
  location: location
  properties: {
    zoneRedundant: zoneRedundant
    reserved: true
  }
  sku: {
    name: 'S1'
    tier: 'Standard'
    capacity: zoneRedundant ? 3 : 1
  }
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: '${resourcePrefix}-as-${appServiceNameSuffix}'
  location: location
  kind: 'app'
  properties: {
    serverFarmId: asAppServicePlan.id
    httpsOnly: true
  }
}
