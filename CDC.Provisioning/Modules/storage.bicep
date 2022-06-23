param location string
param resourcePrefix string
param storageSkuName string
param storageAccountNameSuffix string
var storageResourcePrefix = format('{0}sa', replace(resourcePrefix, '-', ''))
var storageAccountName = '${storageResourcePrefix}${storageAccountNameSuffix}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageSkuName
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

output storageAccountName string = storageAccountName
