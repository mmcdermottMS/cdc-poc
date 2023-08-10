param capacity int
param keyVaultName string
param location string
param name string
param publicNetworkAccess string
param queueDefinitions array
param roleAssignmentDetails array = []
param sku string
param tags object
param timeStamp string
param zoneRedundant bool

resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: name
  location: location
  sku: {
    name: sku
    capacity: capacity
  }
  properties: {
    zoneRedundant: zoneRedundant
    publicNetworkAccess: publicNetworkAccess
    disableLocalAuth: false
  }
  tags: tags
}

resource queues 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = [for queueDefinition in queueDefinitions: {
  name: queueDefinition.name
  parent: serviceBus
  properties: {
    requiresSession: queueDefinition.sessionEnabled
    maxSizeInMegabytes: queueDefinition.maxQueueSizeMb
    maxDeliveryCount: queueDefinition.maxDeliveryCount
  }
}]

resource roleAssigmnents 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleAssignment in roleAssignmentDetails: {
  name: guid(serviceBus.id, roleAssignment.roleDefinitionId, resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionId)
    principalId: roleAssignment.principalId
  }
  scope: serviceBus
}]

module serviceBusConnString 'keyVaultSecret.bicep' = {
  name: '${timeStamp}-kvSecret-serviceBusConnString'
  params: {
    parentKeyVaultName: keyVaultName
    secretName: 'serviceBusConnString'
    secretValue: listKeys('${serviceBus.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBus.apiVersion).primaryConnectionString
  }
}

output id string = serviceBus.id
output hostName string = '${serviceBus.name}.servicebus.windows.net'

/*
resource autoScaleSettings 'Microsoft.Insights/autoscalesettings@2015-04-01' = {
  name: '${serviceBus.name}-autoScaleSettings'
  location: location
  properties: {
    targetResourceUri: serviceBus.id
    enabled: true
    profiles: [
      {
        name: '${serviceBus.name}-autoScaleprofile'
        capacity: {
          minimum: '1'
          maximum: '16'
          default: '16'
        }
        rules: [
          {
            scaleAction: {
              direction: 'Increase'
              type: 'ServiceAllowedNextValue'
              value: '1'
              cooldown: 'PT5M'
            }
            metricTrigger:{
              metricName: 'NamespaceCpuUsage'
              metricNamespace: 'microsoft.servicebus/namespaces'
              metricResourceUri: serviceBus.id
              operator: 'GreaterThan'
              statistic: 'Average'
            }
          }
        ]
      }
    ]
  }
}

/subscriptions/506cf09b-823b-4baa-9155-11e70406819b/resourceGroups/cdc-poc-wus-rg/providers/microsoft.insights/autoscalesettings/cdc-poc-wus-sbns-Autoscale-741
{
    "location": "West US",
    "tags": {},
    "properties": {
        "name": "cdc-poc-wus-sbns-Autoscale-741",
        "enabled": true,
        "targetResourceUri": "/subscriptions/506cf09b-823b-4baa-9155-11e70406819b/resourceGroups/cdc-poc-wus-rg/providers/Microsoft.ServiceBus/namespaces/cdc-poc-wus-sbns",
        "profiles": [
            {
                "name": "Auto created scale condition",
                "capacity": {
                    "minimum": "1",
                    "maximum": "16",
                    "default": "16"
                },
                "rules": [
                    {
                        "scaleAction": {
                            "direction": "Increase",
                            "type": "ServiceAllowedNextValue",
                            "value": "1",
                            "cooldown": "PT5M"
                        },
                        "metricTrigger": {
                            "metricName": "NamespaceCpuUsage",
                            "metricNamespace": "microsoft.servicebus/namespaces",
                            "metricResourceUri": "/subscriptions/506cf09b-823b-4baa-9155-11e70406819b/resourceGroups/cdc-poc-wus-rg/providers/Microsoft.ServiceBus/namespaces/cdc-poc-wus-sbns",
                            "operator": "GreaterThan",
                            "statistic": "Average",
                            "threshold": 70,
                            "timeAggregation": "Maximum",
                            "timeGrain": "PT1M",
                            "timeWindow": "PT5M",
                            "Dimensions": [],
                            "dividePerInstance": false
                        }
                    },
                    {
                        "scaleAction": {
                            "direction": "Increase",
                            "type": "ServiceAllowedNextValue",
                            "value": "1",
                            "cooldown": "PT5M"
                        },
                        "metricTrigger": {
                            "metricName": "NamespaceMemoryUsage",
                            "metricNamespace": "microsoft.servicebus/namespaces",
                            "metricResourceUri": "/subscriptions/506cf09b-823b-4baa-9155-11e70406819b/resourceGroups/cdc-poc-wus-rg/providers/Microsoft.ServiceBus/namespaces/cdc-poc-wus-sbns",
                            "operator": "GreaterThan",
                            "statistic": "Average",
                            "threshold": 70,
                            "timeAggregation": "Maximum",
                            "timeGrain": "PT1M",
                            "timeWindow": "PT5M",
                            "Dimensions": [],
                            "dividePerInstance": false
                        }
                    }
                ]
            }
        ],
        "notifications": [],
        "targetResourceLocation": "West US"
    },

*/
