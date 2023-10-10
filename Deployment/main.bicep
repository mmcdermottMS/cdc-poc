targetScope = 'subscription'

param namePrefix string
param location string
param regionCode string
param allowedIpForStorage string

@description('SKU for the container registry')
param acrSku string

@description('Name of the managed identity that has the AcrPull Role. Specify this value in the parameters.json file to override this default.')
param acrManagedIdentityName string = '${resourcePrefix}-mi-acrPull'

@description('Name of the application insights instance. Specify this value in the parameters.json file to override this default.')
param appInsightsName string = '${resourcePrefix}-ai'

//@description('Name of the Azure Bastion instance. Specify this value in the parameters.json file to override this default.')
//param bastionName string = '${resourcePrefix}-bastion'

@description('Name of the container registry. Limited to 50 chars. Specify this value in the parameters.json file to override this default.')
param containerRegistryName string = length(namePrefix) < 44 ? format('{0}acr', replace(resourcePrefix, '-', '')) : format('{0}{1}acr', substring(replace(namePrefix, '-', ''), 0, 43), regionCode)

@description('Name of the managed identity that has the custom Cosmos DB Role. Specify this value in the parameters.json file to override this default.')
param cosmosWriterMiName string = '${resourcePrefix}-mi-cosmosWriter'

@description('Name of the cosmos db instance. Specify this value in the parameters.json file to override this default.')
param cosmosDbName string = length(namePrefix) < 35 ? '${resourcePrefix}-acdb' : '${substring('${namePrefix}', 0, 34)}-${regionCode}-acdb'

@description('Name of the Event Hub and Service Bus queues that will store the message entities. Specify this value in the parameters.json file to override this default.')
param entityCollectionName string = 'poc.customers.addresses'

@description('Number of days messages will remain in the event hub.')
param ehMessageRetentionInDays int

@description('Number of partitions in the event hub.')
param ehPartitionCount int

@description('Name of the event hub namespace instance. Specify this value in the parameters.json file to override this default.')
param ehnsName string = '${resourcePrefix}-ehns'

@description('Name of the managed identity that has the Event Hub Reader Role. Specify this value in the parameters.json file to override this default.')
param ehnsReceiverManagedIdentityName string = '${resourcePrefix}-mi-ehnsReceiver'

@description('Name of the managed identity that has the Event Hub Sender Role. Specify this value in the parameters.json file to override this default.')
param ehnsSenderManagedIdentityName string = '${resourcePrefix}-mi-ehnsSender'

@description('Name of the ehProducer Function App. Specify this value in the parameters.json file to override this default.')
param ehProducerFaName string = 'ehProducer'

@description('Name of the ehConsumer Function App. Specify this value in the parameters.json file to override this default.')
param ehConsumerFaName string = 'ehConsumer'

@description('Name of the sbConsumer Function App. Specify this value in the parameters.json file to override this default.')
param sbConsumerFaName string = 'sbConsumer'

@description('Name of the pyConsumer Function App. Specify this value in the parameters.json file to override this default.')
param pyConsumerFaName string = 'pyConsumer'

@description('Name of the key vault. Specify this value in the parameters.json file to override this default.')
param keyVaultName string = length(namePrefix) < 17 ? '${resourcePrefix}-kv' : '${substring('${namePrefix}', 0, 16)}-${regionCode}-kv'

@description('Name of the managed identity that has the Key Vault Secrets User Role. Specify this value in the parameters.json file to override this default.')
param kvManagedIdentityName string = '${resourcePrefix}-mi-kvSecretsUser'

@description('Name of the log analytics workspace instance. Specify this value in the parameters.json file to override this default.')
param logAnalyticsWorkspaceName string = '${resourcePrefix}-law'

@description('Maximum number of elastic workers for the function apps.')
param maximumElasticWorkerCount int

@description('Name of the service bus namespace instance. Specify this value in the parameters.json file to override this default.')
param serviceBusName string = '${resourcePrefix}-sbns'

@description('Name of the managed identity that has the Service Bus Owner role. Specify this value in the parameters.json file to override this default.')
param sbnsOwnerMiName string = '${resourcePrefix}-mi-sbnsOwner'

@description('Name of the managed identity that has the Service Bus Sender role. Specify this value in the parameters.json file to override this default.')
param sbnsSenderMiName string = '${resourcePrefix}-mi-sbnsSender'

@description('SKU Tier of the Function App Plan.')
param functionAppSkuTier string

@description('SKU of the storage accounts to use with the premium function apps.')
param storageSku string

//@description('Name of the jump box. Specify this value in the parameters.json file to override this default.')
//param vmName string = length('${namePrefix}') > 6 ? '${substring('${namePrefix}', 0, 6)}-${regionCode}-vm': '${resourcePrefix}-vm'

param cosmosListenerFaName string = 'cosmosListener'

@description('Boolean describing whether or not to enable soft delete on Key Vault - set to TRUE for production')
param enableKvSoftDelete bool = false

@description('Capacity for the event hub namespace')
param ehnsCapacity int

@description('SKU for the service bus namespace')
param ehnsSku string

@description('Capacity for the service bus namespace')
param sbnsCapacity int

@description('SKU for the service bus namespace')
param sbnsSku string

param tags object = {}
param timeStamp string = utcNow('yyyyMMddHHmm')

param resourcePrefix string = '${namePrefix}-${regionCode}'
param workloadResourceGroupName string = '${resourcePrefix}-workload-rg'
param networkResourceGroupName string = '${resourcePrefix}-network-rg'

//Subnet Prefixes and Names
param cosmosListenerSubnetAddressPrefix string
param ehProducerSubnetAddressPrefix string
param ehConsumerSubnetAddressPrefix string
param pyConsumerSubnetAddressPrefix string
param sbConsumerSubnetAddressPrefix string
param peSubnetAddressPrefix string
param peSubnetName string = 'privateEndpoints'
param utilSubnetAddressPrefix string
param utilSubnetName string = 'util'

//Storage Acccount Names
param ehProducerStorageAccountName string = toLower(length('${format('{0}sa', replace(resourcePrefix, '-', ''))}${ehProducerFaName}') > 24 ? substring('${format('{0}sa', replace(resourcePrefix, '-', ''))}${ehProducerFaName}', 0, 24) : '${format('{0}sa', replace(resourcePrefix, '-', ''))}${ehProducerFaName}')
param ehConsumerStorageAccountName string = toLower(length('${format('{0}sa', replace(resourcePrefix, '-', ''))}${ehConsumerFaName}') > 24 ? substring('${format('{0}sa', replace(resourcePrefix, '-', ''))}${ehConsumerFaName}', 0, 24) : '${format('{0}sa', replace(resourcePrefix, '-', ''))}${ehConsumerFaName}')
param sbConsumerStorageAccountName string = toLower(length('${format('{0}sa', replace(resourcePrefix, '-', ''))}${sbConsumerFaName}') > 24 ? substring('${format('{0}sa', replace(resourcePrefix, '-', ''))}${sbConsumerFaName}', 0, 24) : '${format('{0}sa', replace(resourcePrefix, '-', ''))}${sbConsumerFaName}')
param pyConsumerStorageAccountName string = toLower(length('${format('{0}sa', replace(resourcePrefix, '-', ''))}${pyConsumerFaName}') > 24 ? substring('${format('{0}sa', replace(resourcePrefix, '-', ''))}${pyConsumerFaName}', 0, 24) : '${format('{0}sa', replace(resourcePrefix, '-', ''))}${pyConsumerFaName}')
param cosmosListenerStorageAccountName string = toLower(length('${format('{0}sa', replace(resourcePrefix, '-', ''))}${cosmosListenerFaName}') > 24 ? substring('${format('{0}sa', replace(resourcePrefix, '-', ''))}${cosmosListenerFaName}', 0, 24) : '${format('{0}sa', replace(resourcePrefix, '-', ''))}${cosmosListenerFaName}')

//param vmAdminUserName string
//@secure()
//param vmAdminPwd string
param vnetAddressPrefix string

param vnetName string = '${resourcePrefix}-vnet'

param zoneRedundant bool

/**************************************************************/
/*                      RESOURCE GROUPS                       */
/**************************************************************/
resource workloadRg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: workloadResourceGroupName
  location: location
  tags: tags
}

resource networkRg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: networkResourceGroupName
  location: location
  tags: tags
}

/**************************************************************/
/*                        NETWORKING                          */
/**************************************************************/
module networking 'Modules/networking.bicep' = {
  scope: resourceGroup(networkRg.name)
  name: '${timeStamp}-module-networking'
  params: {
    cosmosListenerSubnetAddressPrefix: cosmosListenerSubnetAddressPrefix
    cosmosListenerSubnetName: cosmosListenerFaName
    ehConsumerSubnetAddressPrefix: ehConsumerSubnetAddressPrefix
    ehConsumerSubnetName: ehConsumerFaName
    ehProducerSubnetAddressPrefix: ehProducerSubnetAddressPrefix
    ehProducerSubnetName: ehProducerFaName
    location: location
    peSubnetAddressPrefix: peSubnetAddressPrefix
    peSubnetName: peSubnetName
    pyConsumerSubnetAddressPrefix: pyConsumerSubnetAddressPrefix
    pyConsumerSubnetName: pyConsumerFaName
    resourceGroupName: networkRg.name
    resourcePrefix: resourcePrefix
    sbConsumerSubnetAddressPrefix: sbConsumerSubnetAddressPrefix
    sbConsumerSubnetName: sbConsumerFaName
    tags: tags
    timeStamp: timeStamp
    utilSubnetAddressPrefix: utilSubnetAddressPrefix
    utilSubnetName: utilSubnetName
    vnetAddressPrefix: vnetAddressPrefix
    vnetName: vnetName
  }
}

/**************************************************************/
/*                        MONITORING                          */
/**************************************************************/
module monitoring 'Modules/monitoring.bicep' = {
  scope: resourceGroup(workloadRg.name)
  name: '${timeStamp}-module-monitoring'
  params: {
    appInsightsName: appInsightsName
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    resourceGroupName: workloadRg.name
    tags: tags
    timeStamp: timeStamp
  }
}

/**************************************************************/
/*                        KEY VAULT                           */
/**************************************************************/
module keyVault 'Modules/keyVault.bicep' = {
  scope: resourceGroup(workloadRg.name)
  name: '${timeStamp}-module-keyVault'
  params: {
    enableSoftDelete: enableKvSoftDelete
    kvManagedIdentityName: kvManagedIdentityName
    location: location
    name: keyVaultName
    networkRgName: networkResourceGroupName
    peSubnetName: peSubnetName
    resourcePrefix: resourcePrefix
    tags: tags
    timeStamp: timeStamp
    vnetId: networking.outputs.vnetId
    vnetName: networking.outputs.vnetName
    virtualNetworkRules: [
      {
        id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${networkResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${ehConsumerFaName}'
        ignoreMissingVnetServiceEndpoint: false
      }
      {
        id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${networkResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${ehProducerFaName}'
        ignoreMissingVnetServiceEndpoint: false
      }
      {
        id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${networkResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${sbConsumerFaName}'
        ignoreMissingVnetServiceEndpoint: false
      }
      {
        id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${networkResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${pyConsumerFaName}'
        ignoreMissingVnetServiceEndpoint: false
      }
    ]
    workloadRgName: workloadResourceGroupName
  }
}

/**************************************************************/
/*                   CONTAINER REGISTRY                       */
/**************************************************************/
module containerRegistry 'Modules/containerRegistry.bicep' = {
  scope: resourceGroup(workloadRg.name)
  name: '${timeStamp}-module-containerRegistry'
  params: {
    acrManagedIdentityName: acrManagedIdentityName
    location: location
    name: containerRegistryName
    networkRgName: networkResourceGroupName
    //TODO - uncomment these once private netoworking has been figured out
    //peSubnetName: peSubnetName
    //resourcePrefix: resourcePrefix
    sku: acrSku
    tags: tags
    timeStamp: timeStamp
    vnetId: networking.outputs.vnetId
    vnetName: networking.outputs.vnetName
    workloadRgName: workloadResourceGroupName
  }
}

/**************************************************************/
/*                       SERVICE BUS                          */
/**************************************************************/
module serviceBus 'Modules/serviceBus.bicep' = {
  scope: resourceGroup(workloadRg.name)
  name: '${timeStamp}-module-serviceBus'
  params: {
    capacity: sbnsCapacity
    keyVaultName: keyVaultName
    location: location
    name: serviceBusName
    networkRgName: networkResourceGroupName
    peSubnetName: peSubnetName
    resourcePrefix: resourcePrefix
    sbnsOwnerMiName: sbnsOwnerMiName
    sbnsSenderMiName: sbnsSenderMiName
    sku: sbnsSku
    tags: tags
    timeStamp: timeStamp
    vnetId: networking.outputs.vnetId
    vnetName: networking.outputs.vnetName
    workloadRgName: workloadResourceGroupName
    zoneRedundant: zoneRedundant
  }
  dependsOn: [
    keyVault
  ]
}

/**************************************************************/
/*                        EVENT HUB                           */
/**************************************************************/
module eventHub 'Modules/eventHub.bicep' = {
  scope: resourceGroup(workloadRg.name)
  name: '${timeStamp}-module-eventHub'
  params: {
    capacity: ehnsCapacity
    ehName: entityCollectionName
    ehnsName: ehnsName
    ehnsReceiverManagedIdentityName: ehnsReceiverManagedIdentityName
    ehnsSenderManagedIdentityName: ehnsSenderManagedIdentityName
    keyVaultName: keyVaultName
    location: location
    messageRetentionInDays: ehMessageRetentionInDays
    networkRgName: networkResourceGroupName
    partitionCount: ehPartitionCount
    peSubnetName: peSubnetName
    resourcePrefix: resourcePrefix
    sku: ehnsSku
    tags: tags
    timeStamp: timeStamp
    vnetName: vnetName
    workloadRgName: workloadResourceGroupName
    zoneRedundant: zoneRedundant
  }
  dependsOn: [
    keyVault
  ]
}

/**************************************************************/
/*                        COSMOS DB                           */
/**************************************************************/
module cosmos 'Modules/cosmos.bicep' = {
  scope: resourceGroup(workloadRg.name)
  name: '${timeStamp}-module-cosmos'
  params: {
    cosmosManagedIdentityName: cosmosWriterMiName
    keyVaultName: keyVault.outputs.name
    location: location
    name: cosmosDbName
    networkRgName: networkResourceGroupName
    peSubnetName: peSubnetName
    resourcePrefix: resourcePrefix
    tags: tags
    timeStamp: timeStamp
    vnetId: networking.outputs.vnetId
    vnetName: networking.outputs.vnetName
    workloadRgName: workloadResourceGroupName
  }
}

/**************************************************************/
/*                      FUNCTION APPS                         */
/**************************************************************/
//Moving the private zone setup out of the function app module to avoid repeat deployment for each FA
module privateZoneFa 'Components/privateDnsZone.bicep' = {
  name: '${timeStamp}-fa-privateDnsZone'
  scope: resourceGroup(networkResourceGroupName)
  params: {
    tags: tags
    zoneName: 'privatelink.azurewebsites.net'
  }
  dependsOn: [
    networking
  ]
}

module vnetSbnsZoneLink 'Components/virtualNetworkLink.bicep' = {
  name: '${timeStamp}-fa-privateDnsZone-link'
  scope: resourceGroup(networkResourceGroupName)
  params: {
    vnetName: vnetName
    vnetId: networking.outputs.vnetId
    zoneName: 'privatelink.azurewebsites.net'
    autoRegistration: false
  }
  dependsOn: [
    privateZoneFa
  ]
}

var ehnsReceiverMiId = '/subscriptions/${subscription().subscriptionId}/resourcegroups/${workloadResourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${ehnsReceiverManagedIdentityName}'
var ehnsSenderMiId = '/subscriptions/${subscription().subscriptionId}/resourcegroups/${workloadResourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${ehnsSenderManagedIdentityName}'
var acrPullMiId = '/subscriptions/${subscription().subscriptionId}/resourcegroups/${workloadResourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${acrManagedIdentityName}'
var kvSecretsUserMiId = '/subscriptions/${subscription().subscriptionId}/resourcegroups/${workloadResourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${kvManagedIdentityName}'
var sbnsSenderMiId = '/subscriptions/${subscription().subscriptionId}/resourcegroups/${workloadResourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${sbnsSenderMiName}'
var sbnsOwnerMiId = '/subscriptions/${subscription().subscriptionId}/resourcegroups/${workloadResourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${sbnsOwnerMiName}'
var cosmosWriterMiId = '/subscriptions/${subscription().subscriptionId}/resourcegroups/${workloadResourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${cosmosWriterMiName}'

var functionAppDetails = [
  {
    name: ehProducerFaName
    skuName: 'EP1'
    storageAccountName: ehProducerStorageAccountName
    dockerImageAndTag: 'cdcehproducer:latest'
    functionsWorkerRuntime: 'dotnet'
    functionSpecificAppSettings: [
      {
        name: 'ExternalApiUri'
        value: ''
      }
      {
        name: 'CosmosHost'
        value: 'https://${cosmosDbName}.documents.azure.com:443'
      }
      {
        name: 'CosmosAuthToken'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=cosmosKey)'
      }
      {
        name: 'CosmosInitialAutoscaleThroughput'
        value: '100000'
      }
      {
        name: 'EHNS_SENDER_MI_RESOURCE_ID'
        value: ehnsSenderMiId
      }
      {
        name: 'EhNameSpace'
        value: '${ehnsName}.servicebus.windows.net'
      }
      {
        name: 'EhName'
        value: entityCollectionName
      }
      {
        name: 'PROFILE_ID_MAX_RANGE'
        value: 2000000
      }
      {
        name: 'OVERSIZE_MESSAGE_RATE'
        value: 100000000
      }
    ]
    userAssignedIdentities: {
      '${acrPullMiId}': {}
      '${kvSecretsUserMiId}': {}
      '${ehnsSenderMiId}': {}
    }
  }
  {
    name: ehConsumerFaName
    skuName: 'EP1'
    storageAccountName: ehConsumerStorageAccountName
    dockerImageAndTag: 'cdcehconsumer:latest'
    functionsWorkerRuntime: 'dotnet'
    functionSpecificAppSettings: [
      {
        name: 'ExternalApiUri'
        value: ''
      }
      {
        name: 'ADDITIONAL_SIMULATED_PROC_TIME_MS'
        value: 0
      }
      {
        name: 'EhNameSpace__clientId'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=ehnsReceiverMiClientId)'
      }
      {
        name: 'EhNameSpace__fullyQualifiedNamespace'
        value: '${ehnsName}.servicebus.windows.net'
      }
      {
        name: 'EhName'
        value: entityCollectionName
      }
      {
        name: 'ServiceBusHostName'
        value: '${serviceBusName}.servicebus.windows.net'
      }
      {
        name: 'SBNS_SENDER_MI_RESOURCE_ID'
        value: sbnsSenderMiId
      }
      {
        name: 'QueueName'
        value: entityCollectionName
      }
    ]
    userAssignedIdentities: {
      '${acrPullMiId}': {}
      '${kvSecretsUserMiId}': {}
      '${ehnsReceiverMiId}': {}
      '${sbnsSenderMiId}': {}
    }
  }
  {
    name: sbConsumerFaName
    skuName: 'EP1'
    storageAccountName: sbConsumerStorageAccountName
    dockerImageAndTag: 'cdcsbconsumer:latest'
    functionsWorkerRuntime: 'dotnet'
    functionSpecificAppSettings: [
      {
        name: 'ExternalApiUri'
        value: ''
      }
      {
        name: 'CosmosHost'
        value: 'https://${cosmosDbName}.documents.azure.com:443'
      }
      {
        name: 'COSMOS_WRITER_MI_RESOURCE_ID'
        value: cosmosWriterMiId
      }
      {
        name: 'ServiceBusConnection__fullyQualifiedNamespace'
        value: '${resourcePrefix}-sbns.servicebus.windows.net'
      }
      {
        name: 'ServiceBusConnection__clientId'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=sbnsOwnerMiClientId)'
      }
      {
        name: 'QueueName'
        value: entityCollectionName
      }
    ]
    userAssignedIdentities: {
      '${acrPullMiId}': {}
      '${kvSecretsUserMiId}': {}
      '${sbnsOwnerMiId}': {}
      '${cosmosWriterMiId}': {}
    }
  }
  {
    name: pyConsumerFaName
    skuName: 'EP1'
    storageAccountName: pyConsumerStorageAccountName
    dockerImageAndTag: ''
    functionsWorkerRuntime: 'python'
    functionSpecificAppSettings: [
      {
        name: 'AzureWebJobsFeatureFlags'
        value: 'EnableWorkerIndexing'
      }
      {
        name: 'BUILD_FLAGS'
        value: 'UseExpressBuild'
      }
      {
        name: 'CosmosDBContainerName'
        value: 'addresses'
      }
      {
        name: 'CosmosDBDatabaseName'
        value: 'Customers'
      }
      {
        name: 'CosmosDBEndpoint'
        value: 'https://${cosmosDbName}.documents.azure.com:443'
      }
      {
        name: 'CosmosDBKey'
        value: ''
      }
      {
        name: 'ENABLE_ORYX_BUILD'
        value: 'true'
      }
      {
        name: 'EVENT_HUB_CONN_STR'
        value: ''
      }
      {
        name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
        value: '1'
      }
      {
        name: 'XDG_CACHE_HOME'
        value: '/tmp/.cache'
      }
    ]
    userAssignedIdentities: {
      '${kvSecretsUserMiId}': {}
    }
  }
  {
    name: cosmosListenerFaName
    skuName: 'EP1'
    storageAccountName: cosmosListenerStorageAccountName
    dockerImageAndTag: ''
    functionsWorkerRuntime: 'java'
    functionSpecificAppSettings: [
      {
        name: 'CosmosDbConnString'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=cosmosDbConnString)'
      }
      {
        name: 'CosmosDbDatabase'
        value: 'Customers'
      }
      {
        name: 'ContainerName'
        value: 'addresses'
      }
    ]
    userAssignedIdentities: {
      '${kvSecretsUserMiId}': {}
      '${cosmosWriterMiId}': {}
    }
  }
]

module functionApps 'Modules/functionApps.bicep' = [for functionAppDetail in functionAppDetails: {
  scope: resourceGroup(workloadRg.name)
  name: '${timeStamp}-module-${functionAppDetail.name}'
  params: {
    appInsightsName: appInsightsName
    containerRegistryName: containerRegistryName
    dockerImageAndTag: functionAppDetail.dockerImageAndTag
    functionSpecificAppSettings: functionAppDetail.functionSpecificAppSettings
    functionsWorkerRuntime: functionAppDetail.functionsWorkerRuntime
    kvMiPrincipalId: keyVault.outputs.kvMiId
    location: location
    maximumElasticWorkerCount: maximumElasticWorkerCount
    name: functionAppDetail.name
    networkRgName: networkResourceGroupName
    peSubnetName: peSubnetName
    resourcePrefix: resourcePrefix
    skuName: functionAppDetail.skuName
    skuTier: functionAppSkuTier
    storageAccountName: functionAppDetail.storageAccountName
    storageIpRules: [
      {
        value: allowedIpForStorage
        action: 'Allow'
      }
    ]
    storageSku: storageSku
    subnetId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${networkResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${functionAppDetail.name}'
    tags: tags
    timeStamp: timeStamp
    userAssignedIdentities: functionAppDetail.userAssignedIdentities
    vnetName: vnetName
    workloadResourceGroupName: workloadResourceGroupName
    zoneRedundant: zoneRedundant
  }
  dependsOn: [
    monitoring
    containerRegistry
    keyVault
  ]
}]

/**************************************************************/
/*                        UTILITY VM                          */
/**************************************************************/
// utility server for traffic testing
/*
module utilServer 'Components/virtualMachine.bicep' = {
  name: '${timeStamp}-vm'
  scope: resourceGroup(rg.name)
  params: {
    adminUserName: vmAdminUserName
    adminPassword: vmAdminPwd
    networkResourceGroupName: rg.name
    location: location
    vnetName: networking.outputs.vnetName
    subnetName: utilSubnetName
    os: 'linux'
    vmName: vmName
    vmSize: 'Standard_B2ms'
  }
}
*/
