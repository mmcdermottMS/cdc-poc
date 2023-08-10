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

module cosmosKey 'keyVaultSecret.bicep' = {
  name: '${timeStamp}-kvSecret-cosmosKey'
  params: {
    parentKeyVaultName: keyVaultName
    secretName: 'cosmosKey'
    secretValue: cosmos.listKeys().primaryMasterKey
  }
}

module cosmosConnString 'keyVaultSecret.bicep' = {
  name: '${timeStamp}-kvSecret-cosmosDbConnString'
  params: {
    parentKeyVaultName: keyVaultName
    secretName: 'cosmosDbConnString'
    secretValue: cosmos.listConnectionStrings().connectionStrings[0].connectionString
  }
}

output id string = cosmos.id
