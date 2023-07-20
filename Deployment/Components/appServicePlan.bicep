param location string
param maximumElasticWorkerCount int
param name string
param skuName string
param skuTier string
@allowed([
  'Windows'
  'Linux'
])
param serverOS string
param tags object
param zoneRedundant bool

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: name
  kind: serverOS == 'Windows' ? '' : 'linux'
  location: location
  properties: {
    zoneRedundant: zoneRedundant
    reserved: serverOS == 'Linux'
    maximumElasticWorkerCount: maximumElasticWorkerCount
  }
  sku: {
    name: skuName
    tier: skuTier
    capacity: zoneRedundant ? 3 : 1
  }
  tags: tags
}

output id string = appServicePlan.id
