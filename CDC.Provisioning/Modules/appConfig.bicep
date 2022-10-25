param appName string
param regionCode string
param appServiceNameSuffix string

var resourcePrefix = '${appName}-${regionCode}'
var appServiceAppName = '${resourcePrefix}-${appServiceNameSuffix}'

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: '${resourcePrefix}-ai'
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: format('{0}cr', replace(resourcePrefix, '-', ''))
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: '${resourcePrefix}-sbns'
}

resource eventHub 'Microsoft.EventHub/namespaces@2021-11-01' existing = {
  name: '${resourcePrefix}-ehns'
}

resource appService 'Microsoft.Web/sites@2021-03-01' existing = {
  name: appServiceAppName

  resource appConfig 'config' = {
    name: 'web'
    properties: {
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${appInsights.properties.InstrumentationKey}'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistry.name}.azurecr.io'
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'DOCKER_ENABLE_CI'
          value: 'true'
        }
        {
          name: 'ServiceBusHostName'
          value: '${serviceBus.name}.servicebus.windows.net'
        }
        {
          name: 'ServiceBusConnection__fullyQualifiedNamespace'
          value: '${serviceBus.name}.servicebus.windows.net'
        }
        {
          name: 'EhNameSpace__fullyQualifiedNamespace'
          value: '${eventHub.name}.servicebus.windows.net'
        }
        {
          name: 'EhName'
          value: 'poc.customers.addresses'
        }
        {
          name: 'QueueName'
          value: 'poc.customers.addresses'
        }
        {
          name: 'CosmosHost'
          value: 'https://${resourcePrefix}-acdb.documents.azure.com:443/'
        }
        {
          name: 'BaseWeatherUri'
          value: 'https://${resourcePrefix}-as-weather.azurewebsites.net/'
        }
      ]
    }
  }
}
