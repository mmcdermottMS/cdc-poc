param cosmosManagedIdentityName string
param keyVaultName string
param location string
param networkRgName string
param peSubnetName string
param name string
param resourcePrefix string
param tags object
param timeStamp string
param workloadRgName string
param vnetName string
param vnetId string

module privateZoneCosmos '../Components/privateDnsZone.bicep' = {
  name: '${timeStamp}-cosmos-privateDnsZone'
  scope: resourceGroup(networkRgName)
  params: {
    tags: tags
    zoneName: 'privatelink.documents.azure.com'
  }
}

module vnetCosmosZoneLink '../Components/virtualNetworkLink.bicep' = {
  name: '${timeStamp}-cosmos-privateDnsZone-link'
  scope: resourceGroup(networkRgName)
  params: {
    vnetName: vnetName
    vnetId: vnetId
    zoneName: 'privatelink.documents.azure.com'
    autoRegistration: false
  }
  dependsOn: [
    privateZoneCosmos
  ]
}

module cosmosMi '../Components/managedIdentity.bicep' = {
  scope: resourceGroup(workloadRgName)
  name: '${timeStamp}-kv-mi'
  params: {
    location: location
    name: cosmosManagedIdentityName
    tags: tags
  }
}

module cosmosDb '../Components/cosmos.bicep' = {
  scope: resourceGroup(workloadRgName)
  name: '${timeStamp}-cosmos'
  params: {
    cosmosWriterMiPrincipalId: cosmosMi.outputs.principalId
    cosmosCustomRoleName: guid(name)
    keyVaultName: keyVaultName
    location: location
    name: name
    timeStamp: timeStamp
  }
}

module cosmosPrivateEndpoint '../Components/privateendpoint.bicep' = {
  name: '${timeStamp}-pe-acdb'
  scope: resourceGroup(networkRgName)
  params: {
    dnsResourceGroupName: networkRgName
    dnsZoneName: 'privatelink.documents.azure.com'
    groupId: 'Sql'
    location: location
    networkResourceGroupName: networkRgName
    privateEndpointName: '${resourcePrefix}-pe-acdb'
    serviceResourceId: cosmosDb.outputs.id
    subnetName: peSubnetName
    tags: tags
    vnetName: vnetName
  }
}
