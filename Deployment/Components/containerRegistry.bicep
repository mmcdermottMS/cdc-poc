param location string
param name string
param roleAssignmentDetails array = []
param sku string
param tags object

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  location: location
  name: name
  properties: {
    adminUserEnabled: true //TODO - Figure out how to eliminate this from being required
  }
  sku: {
    name: sku
  }
  tags: tags
}

resource roleAssigmnents 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleAssignment in roleAssignmentDetails: {
  name: guid(containerRegistry.id, roleAssignment.roleDefinitionId, resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionId)
    principalId: roleAssignment.principalId
  }
  scope: containerRegistry
}]

output id string = containerRegistry.id
