param timeStamp string = utcNow('yyyyMMddHHmm')
param appName string
param regionCode string
param storageSkuName string
param location string = resourceGroup().location
param zoneRedundant bool = false
param tenantId string

var resourcePrefix = '${appName}-${regionCode}'

var functionApps = [
  {
    functionAppNameSuffix: 'ehConsumer'
    storageAccountNameSuffix: 'ehconsumer'
    dockerImageAndTag: 'cdcehconsumer:latest'
  }
  {
    functionAppNameSuffix: 'sbConsumer'
    storageAccountNameSuffix: 'sbconsumer'
    dockerImageAndTag: 'cdcsbconsumer:latest'
  }
  {
    functionAppNameSuffix: 'ehProducer'
    storageAccountNameSuffix: 'ehproducer'
    dockerImageAndTag: 'cdcehproducer:latest'
  }
]

var entities = [
  'poc.customers.addresses'
]

module keyVault 'Modules/keyVault.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-kv'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    tenantId: tenantId
  }
}

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

module containerRegistry 'Modules/containerRegistry.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-acr'
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

/*
module ase01 'Modules/ase.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-ase'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    subNetId: vnet.outputs.aseSubnets[0]
    zoneRedundant: zoneRedundant
  }
}

param webApiAspSkuName string = 'I1v2'
param webApiAspSkuTier string = 'IsolatedV2'
param webAppNames array = [
  'order'
  'rx'
]

param webApiServicePlanSku object = {
  name: webApiAspSkuName
  tier: webApiAspSkuTier
  capacity: 1
}

module webApis 'Modules/webApis.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-webApis'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    appServicePlanSku: webApiServicePlanSku
    webAppNames: webAppNames
    aseId: ase01.outputs.id
    zoneRedundant: zoneRedundant
  }
}
*/
