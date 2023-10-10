param acrManagedIdentityName string
param location string
param name string
param networkRgName string
//TODO - uncomment this once private netoworking has been figured out
//param peSubnetName string
//param resourcePrefix string
param sku string
param tags object
param timeStamp string
param workloadRgName string
param vnetId string
param vnetName string

module privateZoneAcr '../Components/privateDnsZone.bicep' = {
  name: '${timeStamp}-acr-privateDnsZone'
  scope: resourceGroup(networkRgName)
  params: {
    tags: tags
    zoneName: 'privatelink.azurecr.io'
  }
}

module vnetAcrZoneLink '../Components/virtualNetworkLink.bicep' = {
  name: '${timeStamp}-acr-privateDnsZone-link'
  scope: resourceGroup(networkRgName)
  params: {
    vnetName: vnetName
    vnetId: vnetId
    zoneName: 'privatelink.azurecr.io'
    autoRegistration: false
  }
  dependsOn: [
    privateZoneAcr
  ]
}

module acrMi '../Components/managedIdentity.bicep' = {
  scope: resourceGroup(workloadRgName)
  name: '${timeStamp}-acr-mi'
  params: {
    location: location
    name: acrManagedIdentityName
    tags: tags
  }
}

module containerRegistry '../Components/containerRegistry.bicep' = {
  name: '${timeStamp}-acr'
  scope: resourceGroup(workloadRgName)
  params: {
    location: location
    name: name
    roleAssignmentDetails: [
      {
        principalId: acrMi.outputs.principalId
        roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d' //AcrPull Role
      }
    ]
    sku: sku
    tags: tags
  }
  dependsOn: [
    acrMi
    privateZoneAcr
  ]
}

//TODO - Temporarily commenting out the PE and private zone until I can figure out how to 
//       properly configure a container registry on a priavte network
/*
module acrPrivateEndpoint '../Components/privateEndpoint.bicep' = {
  name: '${timeStamp}-pe-acr'
  scope: resourceGroup(networkRgName)
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-pe-acr'
    serviceResourceId: containerRegistry.outputs.id
    dnsZoneName: 'privatelink.azurecr.io'
    networkResourceGroupName: networkRgName
    dnsResourceGroupName: networkRgName
    vnetName: vnetName
    subnetName: peSubnetName
    groupId: 'registry'
    tags: tags
  }
}
*/

output acrMiId string = acrMi.outputs.id
