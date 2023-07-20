param enableSoftDelete bool
param kvManagedIdentityName string
param name string
param location string
param networkRgName string
param peSubnetName string
param resourcePrefix string
param timeStamp string
param workloadRgName string
param tags object
param virtualNetworkRules array
param vnetId string
param vnetName string

module privateZoneKv '../Components/privateDnsZone.bicep' = {
  name: '${timeStamp}-kv-privateDnsZone'
  scope: resourceGroup(networkRgName)
  params: {
    tags: tags
    zoneName: 'privatelink.vaultcore.azure.net'
  }
}

module vnetKvZoneLink '../Components/virtualNetworkLink.bicep' = {
  name: '${timeStamp}-kv-privateDnsZone-link'
  scope: resourceGroup(networkRgName)
  params: {
    vnetName: vnetName
    vnetId: vnetId
    zoneName: 'privatelink.vaultcore.azure.net'
    autoRegistration: false
  }
  dependsOn: [
    privateZoneKv
  ]
}

module kvMi '../Components/managedIdentity.bicep' = {
  scope: resourceGroup(workloadRgName)
  name: '${timeStamp}-kv-mi'
  params: {
    location: location
    name: kvManagedIdentityName
    tags: tags
  }
}

module keyVault '../Components/keyVault.bicep' = {
  name: '${timeStamp}-kv'
  scope: resourceGroup(workloadRgName)
  params: {
    enableSoftDelete: enableSoftDelete
    location: location
    name: name
    roleAssignmentDetails: [
      {
        principalId: kvMi.outputs.principalId
        roleDefinitionId: '4633458b-17de-408a-b874-0445c86b69e6' //Key Vault Secrets User
      }
    ]
    tags: tags
    virtualNetworkRules: virtualNetworkRules
  }
  dependsOn: [
    privateZoneKv
    kvMi
  ]
}

module kvPrivateEndpoint '../Components/privateendpoint.bicep' = {
  name: '${timeStamp}-pe-kv'
  scope: resourceGroup(networkRgName)
  params: {
    dnsResourceGroupName: networkRgName
    dnsZoneName: 'privatelink.vaultcore.azure.net'
    groupId: 'vault'
    location: location
    networkResourceGroupName: networkRgName
    privateEndpointName: '${resourcePrefix}-pe-kv'
    serviceResourceId: keyVault.outputs.id
    subnetName: peSubnetName
    tags: tags
    vnetName: vnetName
  }
}

output name string = keyVault.outputs.name
output kvMiId string = kvMi.outputs.id
