param appInsightsName string
param containerRegistryName string
param dockerImageAndTag string
param functionSpecificAppSettings array
param functionsWorkerRuntime string
param keyVaultReferenceIdentity string
param location string
param name string
param serverFarmId string
param storageAccountName string
param storageSku string
param subnetId string
param tags object
param userAssignedIdentities object

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageSku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: subnetId
          action: 'Allow'
        }
      ]
      ipRules: []
      defaultAction: 'Allow'
    }
  }
  tags: tags
}

var storageConnString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'

var baseAppSettings = [
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: appInsights.properties.InstrumentationKey
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: appInsights.properties.ConnectionString
  }
  {
    name: 'AzureWebJobsStorage'
    value: storageConnString
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: functionsWorkerRuntime
  }
  {
    name: 'SCALE_CONTROLLER_LOGGING_ENABLED'
    value: 'AppInsights:Verbose'
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: storageConnString
  }
  {
    name: 'WEBSITE_CONTENTSHARE'
    value: '${toLower(name)}-${substring(uniqueString(name), 0, 4)}'
  }
  {
    name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
    value: 'false'
  }
]

var dockerAppSettings = [
  {
    name: 'DOCKER_REGISTRY_SERVER_URL'
    value: 'https://${containerRegistryName}.azurecr.io'
  }
  {
    name: 'DOCKER_ENABLE_CI'
    value: 'true'
  }
]

var appSettings = dockerImageAndTag == '' ? baseAppSettings : concat(baseAppSettings, dockerAppSettings)

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: name
  location: location
  kind: dockerImageAndTag == '' ? 'functionapp,linux' : 'functionapp,linux,container'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: userAssignedIdentities
  }
  properties: {
    serverFarmId: serverFarmId
    keyVaultReferenceIdentity: keyVaultReferenceIdentity
    httpsOnly: true
    virtualNetworkSubnetId: subnetId
    siteConfig: {
      linuxFxVersion: functionsWorkerRuntime == 'python' ? 'PYTHON|3.9' : functionsWorkerRuntime == 'java' ? 'JAVA|11' : 'DOCKER|${dockerImageAndTag}'
      vnetRouteAllEnabled: true
      functionsRuntimeScaleMonitoringEnabled: true
      appSettings: concat(appSettings, functionSpecificAppSettings)
    }
  }
  tags: tags
}

output id string = functionApp.id
