param nameSuffix string
param location string
param resourcePrefix string
param peSubnetId string
param targetResourceId string
param groupIds array

var acdbPeName = '${resourcePrefix}-pe-${nameSuffix}'
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: acdbPeName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: acdbPeName
        properties: {
          privateLinkServiceId: targetResourceId
          groupIds: groupIds
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: peSubnetId
    }
  }
}
