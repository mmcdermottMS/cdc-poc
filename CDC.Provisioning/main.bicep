param timeStamp string = utcNow('yyyyMMddHHmm')
param appName string
param locationCode string
param storageSkuName string
param location string = resourceGroup().location
param zoneRedundant bool = false

var resourcePrefix = '${appName}-${locationCode}'

var functionApps = [
  {
    functionAppNameSuffix: 'ehConsumer'
    storageAccountNameSuffix: 'ehconsumer'
    dockerImageAndTag: 'cdcehlistener:latest'
  }
  {
    functionAppNameSuffix: 'sbConsumer'
    storageAccountNameSuffix: 'sbconsumer'
    dockerImageAndTag: 'cdcsbconsumer:latest'
  }
]

var entities = [
  'poc.customers.addresses'
]

/*
resource kv 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: 'common-infra-kv-01'
  scope: resourceGroup('506cf09b-823b-4baa-9155-11e70406819b', 'common-infra-rg')
}
*/

module vnet 'Modules/vnet.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-vnet'
  params: {
    location: location
    resourcePrefix: resourcePrefix
  }
}

module monitoring 'Modules/monitoring.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-monitoring'
  params: {
    location: location
    resourcePrefix: resourcePrefix
  }
}

module eventHub 'Modules/eventHub.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-eventHub'
  params: {
    eventHubNames: entities
    location: location 
    resourcePrefix: resourcePrefix
    zoneRedundant: zoneRedundant
  }
}

module serviceBus 'Modules/serviceBus.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-serviceBus'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    zoneRedundant: zoneRedundant
    queueNames: entities
  }
}

module cosmos 'Modules/cosmos.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-cosmos'
  params: {
    location: location
    resourcePrefix: resourcePrefix
  }
}

var functionAppsCount = length(functionApps)
module functions 'Modules/functions.bicep' = [for i in range(0, functionAppsCount): {
  name: '${timeStamp}-${resourcePrefix}-${functionApps[i].functionAppNameSuffix}'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    storageSkuName: storageSkuName
    storageAccountNameSuffix: functionApps[i].storageAccountNameSuffix
    functionAppNameSuffix: functionApps[i].functionAppNameSuffix
    timeStamp: timeStamp
    zoneRedundant: zoneRedundant
    functionSubnetId: vnet.outputs.epfSubnets[i]
    dockerImageAndTag: functionApps[i].dockerImageAndTag
  }
  dependsOn: [
    vnet
    monitoring
  ]
}]
