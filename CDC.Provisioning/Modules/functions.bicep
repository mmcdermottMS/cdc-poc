param location string
param resourcePrefix string
param storageSkuName string
param storageAccountNameSuffix string
param functionAppNameSuffix string
param timeStamp string
param zoneRedundant bool
param functionSubnetId string
param dockerImageAndTag string

//TODO - refactor this out into the main.bicep file, and refactor the storage conn strings into KV instead of
//being passed around as a module output (which is not secure)
module storage 'storage.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-${functionAppNameSuffix}-storage'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    storageSkuName: storageSkuName
    storageAccountNameSuffix: storageAccountNameSuffix
  }
}

resource fxAppServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: '${resourcePrefix}-asp-${functionAppNameSuffix}'
  kind: 'elastic'
  location: location
  properties: {
    zoneRedundant: zoneRedundant
    reserved: true
    maximumElasticWorkerCount: 20
  }
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
    capacity: zoneRedundant ? 3 : 1
  }
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: '${resourcePrefix}-fx-${functionAppNameSuffix}'
  location: location
  kind: 'functionapp,linux,container'
  properties: {
    serverFarmId: fxAppServicePlan.id
    httpsOnly: true
    virtualNetworkSubnetId: functionSubnetId
    siteConfig: {
      linuxFxVersion: 'DOCKER|commoninfraacr.azurecr.io/${dockerImageAndTag}'
      vnetRouteAllEnabled: true
    }
  }

  dependsOn: [
    storage
  ]
}
