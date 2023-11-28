param appInsightsName string
param functionSpecificAppSettings array
param functionsWorkerRuntime string
param keyVaultReferenceIdentity string
param location string
param name string
param serverFarmId string
param storageAccountName string
param storageIpRules array
param storageSku string
param subnetId string
param tags object
param userAssignedIdentities object

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
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
      ipRules: storageIpRules
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
  //{
  //  name: 'WEBSITE_CONTENTOVERVNET'
  //  value: '1'
  //}
]

resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: name
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: userAssignedIdentities
  }
  properties: {
    serverFarmId: serverFarmId
    keyVaultReferenceIdentity: keyVaultReferenceIdentity
    httpsOnly: true
    reserved: true //FLEX PLAN ONLY?
    containerSize: 2048 //FLEX PLAN ONLY?
    siteConfig: {
      netFrameworkVersion: 'v4.0'
      linuxFxVersion: 'DOTNET-ISOLATED|6.0'
      preWarmedInstanceCount: 0
      functionAppScaleLimit: 100
      appSettings: concat(baseAppSettings, functionSpecificAppSettings)
    }
  }
  tags: tags
}

output id string = functionApp.id
