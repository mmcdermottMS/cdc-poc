param appInsightsName string
param containerRegistryName string
param dockerImageAndTag string
param functionSpecificAppSettings array
param functionsWorkerRuntime string
param kvMiPrincipalId string
param location string
param maximumElasticWorkerCount int
param networkRgName string
param name string
param peSubnetName string
param resourcePrefix string
param skuName string
param skuTier string
param storageAccountName string
param storageSku string
param subnetId string
param tags object
param timeStamp string
param userAssignedIdentities object
param vnetName string
param workloadResourceGroupName string
param zoneRedundant bool
//var subnetId = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${networkRgName}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${name}'

module appServicePlan '../Components/appServicePlan.bicep' = {
  scope: resourceGroup(workloadResourceGroupName)
  name: '${timeStamp}-${name}-asp'
  params: {
    location: location
    maximumElasticWorkerCount: maximumElasticWorkerCount
    name: '${resourcePrefix}-asp-${name}'
    serverOS: 'Linux'
    skuName: skuName
    skuTier: skuTier
    tags: tags
    zoneRedundant: zoneRedundant
  }
}

module functionApp '../Components/functionApp.bicep' = {
  name: '${timeStamp}-fa-${name}'
  params: {
    appInsightsName: appInsightsName
    containerRegistryName: containerRegistryName
    dockerImageAndTag: dockerImageAndTag
    functionSpecificAppSettings: functionSpecificAppSettings
    functionsWorkerRuntime: functionsWorkerRuntime
    keyVaultReferenceIdentity: kvMiPrincipalId
    location: location
    name: '${resourcePrefix}-fa-${name}'
    serverFarmId: appServicePlan.outputs.id
    storageAccountName: storageAccountName
    storageSku: storageSku
    subnetId: subnetId
    tags: tags
    userAssignedIdentities: userAssignedIdentities
  }
  dependsOn: [
    appServicePlan
  ]
}

module ehPrivateEndpoint '../Components/privateendpoint.bicep' = {
  name: '${timeStamp}-pe-${name}'
  scope: resourceGroup(networkRgName)
  params: {
    dnsResourceGroupName: networkRgName
    dnsZoneName: 'privatelink.azurewebsites.net'
    groupId: 'sites'
    location: location
    networkResourceGroupName: networkRgName
    privateEndpointName: '${resourcePrefix}-pe-${name}'
    serviceResourceId: functionApp.outputs.id
    subnetName: peSubnetName
    tags: tags
    vnetName: vnetName
  }
}
