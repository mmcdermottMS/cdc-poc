param location string
param ehConsumerSubnetAddressPrefix string
param ehConsumerSubnetName string
param ehProducerSubnetAddressPrefix string
param ehProducerSubnetName string
param peSubnetAddressPrefix string
param peSubnetName string
param pyConsumerSubnetAddressPrefix string
param pyConsumerSubnetName string
param resourcePrefix string
param resourceGroupName string
param sbConsumerSubnetAddressPrefix string
param sbConsumerSubnetName string
param tags object
param timeStamp string
param utilSubnetAddressPrefix string
param utilSubnetName string
param vnetName string
param vnetAddressPrefix string

module vnet '../Components/vnet.bicep' = {
  name: '${timeStamp}-vnet'
  params: {
    location: location
    name: vnetName
    addressPrefixes: [
      vnetAddressPrefix
    ]
    subnets: [
      {
        name: utilSubnetName
        properties: {
          addressPrefix: utilSubnetAddressPrefix
          networkSecurityGroup: {
            id: utilNsg.outputs.id
          }
        }
      }
      {
        name: peSubnetName
        properties: {
          addressPrefix: peSubnetAddressPrefix
          networkSecurityGroup: {
            id: privateEndpointsNsg.outputs.id
          }
        }
      }
      {
        name: ehProducerSubnetName
        properties: {
          addressPrefix: ehProducerSubnetAddressPrefix
          networkSecurityGroup: {
            id: functionNsg.outputs.id
          }
          delegations: [
            {
              name: '${resourcePrefix}-asp-delegation-${substring(uniqueString(deployment().name), 0, 4)}'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          serviceENdpoints: [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.KeyVault'
            }
          ]
        }
      }
      {
        name: ehConsumerSubnetName
        properties: {
          addressPrefix: ehConsumerSubnetAddressPrefix
          networkSecurityGroup: {
            id: functionNsg.outputs.id
          }
          delegations: [
            {
              name: '${resourcePrefix}-asp-delegation-${substring(uniqueString(deployment().name), 0, 4)}'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          serviceENdpoints: [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.KeyVault'
            }
          ]
        }
      }
      {
        name: pyConsumerSubnetName
        properties: {
          addressPrefix: pyConsumerSubnetAddressPrefix
          networkSecurityGroup: {
            id: functionNsg.outputs.id
          }
          delegations: [
            {
              name: '${resourcePrefix}-asp-delegation-${substring(uniqueString(deployment().name), 0, 4)}'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          serviceENdpoints: [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.KeyVault'
            }
          ]
        }
      }
      {
        name: sbConsumerSubnetName
        properties: {
          addressPrefix: sbConsumerSubnetAddressPrefix
          networkSecurityGroup: {
            id: functionNsg.outputs.id
          }
          delegations: [
            {
              name: '${resourcePrefix}-asp-delegation-${substring(uniqueString(deployment().name), 0, 4)}'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          serviceENdpoints: [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.KeyVault'
            }
          ]
        }
      }
    ]
    tags: tags
  }
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    utilNsg
    privateEndpointsNsg
    functionNsg
  ]
}

// NSG for Util subnet
module utilNsg '../Components/nsg.bicep' = {
  name: '${timeStamp}-nsg-util'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: '${resourcePrefix}-nsg-util'
    location: location
    securityRules: [
      {
        name: 'allow-remote-vm-connections'
        properties: {
          priority: 100
          protocol: '*'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
        }
      }
      {
        name: 'deny-inbound-default'
        properties: {
          priority: 200
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// NSG for Private Endpoints subnet
module privateEndpointsNsg '../Components/nsg.bicep' = {
  name: '${timeStamp}-nsg-pe'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: '${resourcePrefix}-nsg-pe'
    location: location
    securityRules: [
      {
        name: 'deny-inbound-default'
        properties: {
          priority: 120
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// NSG for EH Producer Integration subnet
module functionNsg '../Components/nsg.bicep' = {
  name: '${timeStamp}-nsg-functions'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: '${resourcePrefix}-nsg-functions'
    location: location
    securityRules: []
  }
}

output vnetId string = vnet.outputs.id
output vnetName string = vnet.outputs.name
