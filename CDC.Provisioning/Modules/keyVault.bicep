param location string
param resourcePrefix string
param tenantId string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name:'${resourcePrefix}-kv'
  location: location
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: tenantId
    accessPolicies: []
    enableSoftDelete: false
    enableRbacAuthorization: true
  }
}
