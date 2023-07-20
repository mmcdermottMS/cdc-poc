param capacity int
param ehName string
param ehnsName string
param ehnsReceiverManagedIdentityName string
param ehnsSenderManagedIdentityName string
param keyVaultName string
param location string
param messageRetentionInDays int
param networkRgName string
param partitionCount int
param peSubnetName string
param resourcePrefix string
param sku string
param tags object
param timeStamp string
param workloadRgName string
param vnetName string
param zoneRedundant bool

module ehnsReceiverMi '../Components/managedIdentity.bicep' = {
  scope: resourceGroup(workloadRgName)
  name: '${timeStamp}-ehns-mi-reader'
  params: {
    location: location
    name: ehnsReceiverManagedIdentityName
    tags: tags
  }
}

module receiverClientIdSecret '../Components/keyVaultSecret.bicep' = {
  name: '${timeStamp}-kvSecret-ehnsReceiverMiClientId'
  params: {
    parentKeyVaultName: keyVaultName
    secretName: 'ehnsReceiverMiClientId'
    secretValue: ehnsReceiverMi.outputs.clientId
  }
}

module ehnsSenderMi '../Components/managedIdentity.bicep' = {
  scope: resourceGroup(workloadRgName)
  name: '${timeStamp}-ehns-mi-sender'
  params: {
    location: location
    name: ehnsSenderManagedIdentityName
    tags: tags
  }
}

module eventHub '../Components/eventHub.bicep' = {
  name: '${timeStamp}-ehns'
  scope: resourceGroup(workloadRgName)
  params: {
    capacity: capacity
    eventHubDetails: [
      {
        name: ehName
        partitionCount: partitionCount
        messageRetentionInDays: messageRetentionInDays
      }
    ]
    location: location
    name: ehnsName
    publicNetworkAccess: 'Disabled'
    roleAssignmentDetails: [
      {
        principalId: ehnsReceiverMi.outputs.principalId
        roleDefinitionId: 'a638d3c7-ab3a-418d-83e6-5f17a39d4fde' //Event Hubs Data Receiver Role
      }
      {
        principalId: ehnsSenderMi.outputs.principalId
        roleDefinitionId: '2b629674-e913-4c01-ae53-ef4638d8f975' //Event Hubs Data Sender Role
      }
    ]
    sku: sku
    zoneRedundant: zoneRedundant
  }
  dependsOn: [
    ehnsReceiverMi
    ehnsSenderMi
  ]
}

module ehPrivateEndpoint '../Components/privateendpoint.bicep' = {
  name: '${timeStamp}-pe-ehns'
  scope: resourceGroup(networkRgName)
  params: {
    dnsResourceGroupName: networkRgName
    dnsZoneName: 'privatelink.servicebus.windows.net'
    groupId: 'namespace'
    location: location
    networkResourceGroupName: networkRgName
    privateEndpointName: '${resourcePrefix}-pe-ehns'
    serviceResourceId: eventHub.outputs.id
    subnetName: peSubnetName
    tags: tags
    vnetName: vnetName
  }
}

output ehnsReceiverMiId string = ehnsReceiverMi.outputs.id
output ehnsSenderMiId string = ehnsSenderMi.outputs.id
