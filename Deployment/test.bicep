targetScope = 'subscription'

param namePrefix string
param location string
param regionCode string

@description('Name of the ehProducer Function App. Specify this value in the parameters.json file to override this default.')
param ehProducerFaName string = 'ehProducer'

@description('Name of the ehConsumer Function App. Specify this value in the parameters.json file to override this default.')
param ehConsumerFaName string = 'ehConsumer'

@description('Name of the sbConsumer Function App. Specify this value in the parameters.json file to override this default.')
param sbConsumerFaName string = 'sbConsumer'

@description('Name of the pyConsumer Function App. Specify this value in the parameters.json file to override this default.')
param pyConsumerFaName string = 'pyConsumer'

@description('Name of the cosmosListener Function App. Specify this value in the parameters.json file to override this default.')
param cosmosListenerFaName string = 'cosmosListener'

@description('Name of the application insights instance. Specify this value in the parameters.json file to override this default.')
param appInsightsName string = '${resourcePrefix}-ai'

@description('Name of the log analytics workspace instance. Specify this value in the parameters.json file to override this default.')
param logAnalyticsWorkspaceName string = '${resourcePrefix}-law'

@description('Boolean describing whether or not to enable soft delete on Key Vault - set to TRUE for production')
param enableKvSoftDelete bool = false

@description('Name of the managed identity that has the Key Vault Secrets User Role. Specify this value in the parameters.json file to override this default.')
param kvManagedIdentityName string = '${resourcePrefix}-mi-kvSecretsUser'

@description('Name of the key vault. Specify this value in the parameters.json file to override this default.')
param keyVaultName string = length(namePrefix) < 17 ? '${resourcePrefix}-kv' : '${substring('${namePrefix}', 0, 16)}-${regionCode}-kv'

param tags object = {}
param timeStamp string = utcNow('yyyyMMddHHmm')
param resourcePrefix string = '${namePrefix}-${regionCode}'
param workloadResourceGroupName string = '${resourcePrefix}-workload-rg'
param networkResourceGroupName string = '${resourcePrefix}-network-rg'
param cosmosListenerSubnetAddressPrefix string
param ehProducerSubnetAddressPrefix string
param ehConsumerSubnetAddressPrefix string
param pyConsumerSubnetAddressPrefix string
param sbConsumerSubnetAddressPrefix string
param peSubnetAddressPrefix string
param peSubnetName string = 'privateEndpoints'
param utilSubnetAddressPrefix string
param utilSubnetName string = 'util'
param vnetAddressPrefix string
param vnetName string = '${resourcePrefix}-vnet'

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
