param capacity int
param eventHubDetails array
param location string
param name string
param publicNetworkAccess string
param roleAssignmentDetails array = []
param sku string
param zoneRedundant bool

resource eventHubNameSpace 'Microsoft.EventHub/namespaces@2022-10-01-preview' = {
  name: name
  location: location
  properties: {
    //zoneRedundant: zoneRedundant
    publicNetworkAccess: publicNetworkAccess
    disableLocalAuth: true
  }
  sku: {
    name: sku
    capacity: capacity
  }
}

resource eventHubs 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' = [for eventHubDetail in eventHubDetails: {
  name: eventHubDetail.name
  parent: eventHubNameSpace
  properties: {
    partitionCount: eventHubDetail.partitionCount
    messageRetentionInDays: eventHubDetail.messageRetentionInDays
  }
}]

resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleAssignment in roleAssignmentDetails: {
  name: guid(eventHubNameSpace.id, roleAssignment.roleDefinitionId, resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionId)
    principalId: roleAssignment.principalId
  }
  scope: eventHubNameSpace
}]

output id string = eventHubNameSpace.id
output hostName string = '${eventHubNameSpace.name}.servicebus.windows.net'
