param storageAccountName string
param location string
param sku string
param timeStamp string
param tags object
param targetSubnetId string

module ehProducerStorage '../Components/storageAccount.bicep' = {
  name: '${timeStamp}-${storageAccountName}-lockdown'
  params: {
    defaultAction: 'Deny'
    location: location
    name: storageAccountName
    sku: sku
    tags: tags
    targetSubnetId: targetSubnetId
  }
}
