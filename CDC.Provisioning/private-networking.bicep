param timeStamp string = utcNow('yyyyMMddHHmm')
param appName string
param regionCode string
param location string = resourceGroup().location
param subscriptionId string
var resourcePrefix = '${appName}-${regionCode}'
var peSubnetId = '/subscriptions/${subscriptionId}/resourceGroups/${resourcePrefix}-rg/providers/Microsoft.Network/virtualNetworks/${resourcePrefix}-vnet-01/subnets/${resourcePrefix}-subnet-privateEndpoints'

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' existing = {
  name: '${resourcePrefix}-acdb'
}
resource ehns 'Microsoft.EventHub/namespaces@2021-11-01' existing = {
  name: '${resourcePrefix}-ehns'
}
resource sbns 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: '${resourcePrefix}-sbns'
}
resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: '${resourcePrefix}-kv'
}
resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: '${replace(resourcePrefix, '-', '')}acr'
}

// functions - sites



var peTargetResources = [
  {
    nameSuffix: 'acdb'
    id: cosmos.id
    groupIds: [
      'Sql'
    ]
  }
  {
    nameSuffix: 'ehns'
    id: ehns.id
    groupIds: [
      'namespace'
    ]
  }
  {
    nameSuffix: 'sbns'
    id: sbns.id
    groupIds: [
      'namespace'
    ]
  }
  {
    nameSuffix: 'kv'
    id: kv.id
    groupIds: [
      'vault'
    ]
  }
  {
    nameSuffix: 'acr'
    id: acr.id
    groupIds: [
      'registry'
    ]
  }
]

module dnsZones 'Modules/dnsZones.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-dnsZones}'
}

var targetResourceCount = length(peTargetResources)
module privateEndpoints 'Modules/privateEndpoints.bicep' = [for i in range(0, targetResourceCount): {
  name: '${timeStamp}-${resourcePrefix}-pe-${peTargetResources[i].nameSuffix}'
  params: {
    nameSuffix: peTargetResources[i].nameSuffix
    location: location
    resourcePrefix: resourcePrefix
    peSubnetId: peSubnetId
    targetResourceId: peTargetResources[i].id
    groupIds: peTargetResources[i].groupIds
  }
}]
