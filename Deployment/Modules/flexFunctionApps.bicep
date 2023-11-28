param appInsightsName string
param functionSpecificAppSettings array
param functionsWorkerRuntime string
param kvMiPrincipalId string
param location string
param maximumElasticWorkerCount int
param name string
param resourcePrefix string
param serverOS string
param skuName string
param skuTier string
param storageAccountName string
param storageIpRules array
param storageSku string
param subnetId string
param tags object
param timeStamp string
param userAssignedIdentities object
param workloadResourceGroupName string
param zoneRedundant bool

module appServicePlan '../Components/appServicePlan.bicep' = {
  scope: resourceGroup(workloadResourceGroupName)
  name: '${timeStamp}-${name}-asp'
  params: {
    location: location
    maximumElasticWorkerCount: maximumElasticWorkerCount
    name: '${resourcePrefix}-asp-${name}'
    serverOS: serverOS
    skuName: skuName
    skuTier: skuTier
    tags: tags
    zoneRedundant: zoneRedundant
  }
}

module functionApp '../Components/flexFunctionApp.bicep' = {
  name: '${timeStamp}-fa-${name}'
  params: {
    appInsightsName: appInsightsName
    functionSpecificAppSettings: functionSpecificAppSettings
    functionsWorkerRuntime: functionsWorkerRuntime
    keyVaultReferenceIdentity: kvMiPrincipalId
    location: location
    name: '${resourcePrefix}-fa-${name}'
    serverFarmId: appServicePlan.outputs.id
    storageAccountName: storageAccountName
    storageIpRules: storageIpRules
    storageSku: storageSku
    subnetId: subnetId
    tags: tags
    userAssignedIdentities: userAssignedIdentities
  }
  dependsOn: [
    appServicePlan
  ]
}
