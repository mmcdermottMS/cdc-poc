param enableSoftDelete bool
param location string
param name string
param roleAssignmentDetails array = []
param tags object
param tenantId string = tenant().tenantId
param virtualNetworkRules array

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: tenantId
    accessPolicies: []
    enableSoftDelete: enableSoftDelete
    enableRbacAuthorization: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: virtualNetworkRules
    }    
  }
  tags: tags
}

//Defining role assignments here so that the scope can be set to this specific resource
resource roleAssigmnents 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleAssignment in roleAssignmentDetails: {
  name: guid(keyVault.id, roleAssignment.roleDefinitionId, resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionId)
    principalId: roleAssignment.principalId
  }
  scope: keyVault
}]

output id string = keyVault.id
output name string = keyVault.name
