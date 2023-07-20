param appInsightsName string
param location string
param logAnalyticsWorkspaceName string
param resourceGroupName string
param tags object
param timeStamp string

module logAnalyticsWorkspace '../Components/logAnalyticsWorkspace.bicep' = {
  name: '${timeStamp}-law'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    name: logAnalyticsWorkspaceName
    tags: tags
  }
}

module appInsights '../Components/appInsights.bicep' = {
  name: '${timeStamp}-app-insights'
  scope: resourceGroup(resourceGroupName)
  params: {
    logAnalyticsId: logAnalyticsWorkspace.outputs.id
    location: location
    name: appInsightsName
    tags: tags
  }
  dependsOn: [
    logAnalyticsWorkspace
  ]
}
