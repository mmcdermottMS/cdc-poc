param location string
param name string
param securityRules array

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: name
  location: location
  properties: {
    securityRules: securityRules
  }
}

output id string = nsg.id
output name string = nsg.name
