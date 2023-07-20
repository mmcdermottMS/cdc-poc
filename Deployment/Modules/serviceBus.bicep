param capacity int
param keyVaultName string
param location string
param networkRgName string
param peSubnetName string
param name string
param resourcePrefix string
param sbnsOwnerMiName string
param sbnsSenderMiName string
param sku string
param tags object
param timeStamp string
param workloadRgName string
param vnetId string
param vnetName string
param zoneRedundant bool

module privateZoneSbns '../Components/privateDnsZone.bicep' = {
  name: '${timeStamp}-sbns-privateDnsZone'
  scope: resourceGroup(networkRgName)
  params: {
    tags: tags
    zoneName: 'privatelink.servicebus.windows.net'
  }
}

module vnetSbnsZoneLink '../Components/virtualNetworkLink.bicep' = {
  name: '${timeStamp}-sbns-privateDnsZone-link'
  scope: resourceGroup(networkRgName)
  params: {
    vnetName: vnetName
    vnetId: vnetId
    zoneName: 'privatelink.servicebus.windows.net'
    autoRegistration: false
  }
  dependsOn: [
    privateZoneSbns
  ]
}

module sbnsOwnerMi '../Components/managedIdentity.bicep' = {
  scope: resourceGroup(workloadRgName)
  name: '${timeStamp}-sbns-owner-mi'
  params: {
    location: location
    name: sbnsOwnerMiName
    tags: tags
  }
}

module ownerClientIdSecret '../Components/keyVaultSecret.bicep' = {
  name: '${timeStamp}-kvSecret-sbnsOwnerMiClientId'
  params: {
    parentKeyVaultName: keyVaultName
    secretName: 'sbnsOwnerMiClientId'
    secretValue: sbnsOwnerMi.outputs.clientId
  }
}

module sbnsSenderMi '../Components/managedIdentity.bicep' = {
  scope: resourceGroup(workloadRgName)
  name: '${timeStamp}-sbns-sender-mi'
  params: {
    location: location
    name: sbnsSenderMiName
    tags: tags
  }
}

module serviceBus '../Components/serviceBus.bicep' = {
  name: '${timeStamp}-sbns'
  scope: resourceGroup(workloadRgName)
  params: {
    capacity: capacity
    location: location
    name: name
    publicNetworkAccess: 'Disabled'
    queueDefinitions: [
      {
        name: 'poc.customers.addresses'
        sessionEnabled: true
        maxMessageSizeKb: 10
        maxQueueSizeMb: 2048
        maxDeliveryCount: 3
      }
    ]
    roleAssignmentDetails: [
      {
        principalId: sbnsOwnerMi.outputs.principalId
        roleDefinitionId: '090c5cfd-751d-490a-894a-3ce6f1109419' //Service Bus Data Owner Role
      }
      {
        principalId: sbnsSenderMi.outputs.principalId
        roleDefinitionId: '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39' //Service Bus Data Sender Role
      }
    ]
    sku: sku
    tags: tags
    zoneRedundant: zoneRedundant
  }
  dependsOn: [
    privateZoneSbns
    sbnsOwnerMi
  ]
}

module sbPrivateEndpoint '../Components/privateendpoint.bicep' = {
  name: '${timeStamp}-pe-sbns'
  scope: resourceGroup(networkRgName)
  params: {
    dnsResourceGroupName: networkRgName
    dnsZoneName: 'privatelink.servicebus.windows.net'
    groupId: 'namespace'
    location: location
    networkResourceGroupName: networkRgName
    privateEndpointName: '${resourcePrefix}-pe-sbns'
    serviceResourceId: serviceBus.outputs.id
    subnetName: peSubnetName
    tags: tags
    vnetName: vnetName
  }
}
