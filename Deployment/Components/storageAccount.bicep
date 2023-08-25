param defaultAction string
param ipRules array
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
      ipRules: ipRules
      defaultAction: defaultAction
    }
  }
  tags: tags
}
