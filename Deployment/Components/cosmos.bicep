param cosmosCustomRoleName string
param cosmosWriterMiPrincipalId string
param keyVaultName string
param location string
param name string
param timeStamp string

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: name
  location: location
  properties: {
    locations: [
      {
        locationName: location
      }
    ]
    databaseAccountOfferType: 'Standard'
    networkAclBypass: 'AzureServices'
    publicNetworkAccess: 'Disabled'
  }
}

resource cosmosCustomRole 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2022-11-15' = {
  parent: cosmos
  name: cosmosCustomRoleName
  properties: {
    roleName: cosmosCustomRoleName
    type: 'CustomRole'
    assignableScopes: [
      cosmos.id
    ]
    permissions: [
      {
        dataActions: [
          'Microsoft.DocumentDB/databaseAccounts/readMetadata'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*'
        ]
      }
    ]
  }
}

resource roleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-11-15' = {
  parent: cosmos
  name: guid(cosmosWriterMiPrincipalId)
  properties: {
    roleDefinitionId: cosmosCustomRole.id
    principalId: cosmosWriterMiPrincipalId
    scope: cosmos.id
  }
}

module vmPasswordSecret 'keyVaultSecret.bicep' = {
  name: '${timeStamp}-kvSecret-vmPassword'
  params: {
    parentKeyVaultName: keyVaultName
    secretName: 'cosmosKey'
    secretValue: cosmos.listKeys().primaryMasterKey
  }
}

//output foo string = cosmos.

/*
resource roleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-11-15' = [for principalIdDetail in principalIdDetails: {
  parent: cosmos
  name: principalIdDetail.name
  properties: {
    roleDefinitionId: cosmosCustomRole.id
    principalId: principalIdDetail.principalId
    scope: cosmos.id
  }
}]

module privateEndpoint 'privateendpoint.bicep' = {
  name: '${timeStamp}-pe-cosmos'
  scope: resourceGroup(networkResourceGroupName)
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-pe-cosmos'
    serviceResourceId: cosmos.id
    dnsZoneName: 'privatelink.documents.azure.com'
    networkResourceGroupName: networkResourceGroupName
    dnsResourceGroupName: dnsResourceGroupName
    vnetName: vnetName
    subnetName: 'privateEndpoints'
    groupId: 'Sql'
  }
}
*/

output id string = cosmos.id
