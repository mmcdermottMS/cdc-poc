param defaultAction string = 'Allow' //Has to default to Allow initially to let the function apps deploy correctly, will be set to deny in a later step
param location string
param name string
param sku string
param tags object
param targetSubnetId string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: targetSubnetId
          action: 'Allow'
        }
      ]
      ipRules: []
      defaultAction: defaultAction
    }
  }
  tags: tags
}
