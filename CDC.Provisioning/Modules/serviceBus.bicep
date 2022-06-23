param resourcePrefix string
param location string
param zoneRedundant bool
param queueNames array

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: '${resourcePrefix}-sbns-01'
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    zoneRedundant: zoneRedundant
  }
}

resource queues 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = [for queueName in queueNames: {
  name: queueName
  parent: serviceBus
  properties: {
    requiresSession: true
  }
}]

output hostName string = '${serviceBus.name}.servicebus.windows.net'
