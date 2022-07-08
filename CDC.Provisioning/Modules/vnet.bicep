param location string
param resourcePrefix string

@description('The IP address range for all virtual networks to use.')
param virtualNetworkAddressPrefix string = '10.1.0.0/20'

@description('The name and IP address range for each subnet in the virtual networks.')
param subnets array = [
  {
    suffix: 'subnet-util'
    name: '${resourcePrefix}-subnet-util'
    ipAddressRange: '10.1.0.0/22'
    delegations: []
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
    ]
  }
  {
    suffix: 'subnet-privateEndpoints'
    name: '${resourcePrefix}-subnet-privateEndpoints'
    ipAddressRange: '10.1.4.0/22'
    delegations: []
    serviceEndpoints: []
  }
  {
    suffix: 'subnet-epf-01'
    name: '${resourcePrefix}-subnet-epf-01'
    ipAddressRange: '10.1.10.0/26'
    delegations: [
      {
        name: '${resourcePrefix}-asp-delegation-${substring(uniqueString(deployment().name), 0, 4)}'
        properties: {
          serviceName: 'Microsoft.Web/serverfarms'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
      }
    ]
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
    ]
  }
  {
    suffix: 'subnet-epf-02'
    name: '${resourcePrefix}-subnet-epf-02'
    ipAddressRange: '10.1.10.64/26'
    delegations: [
      {
        name: '${resourcePrefix}-asp-delegation-${substring(uniqueString(deployment().name), 0, 4)}'
        properties: {
          serviceName: 'Microsoft.Web/serverfarms'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
      }
    ]
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
    ]
  }
]

resource networkSecurityGroups 'Microsoft.Network/networkSecurityGroups@2022-01-01' = [for subnet in subnets: {
  name: '${resourcePrefix}-nsg-${subnet.suffix}'
  location: location
  properties: {
    securityRules: []
  }
}]

resource virtualNetworks 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: '${resourcePrefix}-vnet-01'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.ipAddressRange
        delegations: subnet.delegations
        serviceEndpoints: subnet.serviceEndpoints
        networkSecurityGroup: {
          id: resourceId('Microsoft.Network/networkSecurityGroups', '${resourcePrefix}-nsg-${subnet.suffix}')
        }
      }
    }]
  }
  dependsOn: [
    networkSecurityGroups
  ]
}

output epfSubnets array = [
  resourceId('Microsoft.Network/VirtualNetworks/subnets', virtualNetworks.name, '${resourcePrefix}-subnet-epf-01')
  resourceId('Microsoft.Network/VirtualNetworks/subnets', virtualNetworks.name, '${resourcePrefix}-subnet-epf-02')
  resourceId('Microsoft.Network/VirtualNetworks/subnets', virtualNetworks.name, '${resourcePrefix}-subnet-epf-03')
]

output privateEndpointsSubnetId string = resourceId('Microsoft.Network/VirtualNetworks/subnets', virtualNetworks.name, '${resourcePrefix}-subnet-privateEndpoints')
output virtualNetworkId string = virtualNetworks.id
