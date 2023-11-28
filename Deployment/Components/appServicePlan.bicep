param location string
param maximumElasticWorkerCount int
param name string
param skuName string
param skuTier string
@allowed([
  'Windows'
  'Linux'
  'flex'
])
param serverOS string
param tags object
param zoneRedundant bool

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: name
  kind: serverOS == 'Windows' ? '' : serverOS == 'flex' ? 'functionapp' : 'linux'
  location: location
  properties: {
    zoneRedundant: zoneRedundant
    reserved: serverOS == 'Linux' || serverOS == 'flex'
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
