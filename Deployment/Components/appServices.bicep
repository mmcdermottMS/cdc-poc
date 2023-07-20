param location string
param resourcePrefix string
param appServiceNameSuffix string
param timeStamp string
param zoneRedundant bool

module asp 'appServicePlan.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-asp-${appServiceNameSuffix}'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    appNameSuffix: appServiceNameSuffix
    serverOS: 'Linux'
    zoneRedundant: zoneRedundant
    skuName: zoneRedundant ? 'P1v2' : 'S1'
    skuTier: zoneRedundant ? 'PremiumV2' : 'Standard'
  }
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: '${resourcePrefix}-as-${appServiceNameSuffix}'
  location: location
  kind: 'app'
  properties: {
    serverFarmId: asp.outputs.resourceId
    httpsOnly: true
  }
}
