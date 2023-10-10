targetScope = 'subscription'

param namePrefix string
param location string
param regionCode string
param tags object = {}
param resourcePrefix string = '${namePrefix}-${regionCode}'
param workloadResourceGroupName string = '${resourcePrefix}-workload-rg'
param networkResourceGroupName string = '${resourcePrefix}-network-rg'

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
