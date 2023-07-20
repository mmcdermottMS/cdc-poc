//https://docs.microsoft.com/en-us/azure/templates/microsoft.network/privateendpoints?tabs=bicep#privatelinkserviceconnection

resource privateDnsZoneBlob 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'Global'
}

resource privateDnsZoneFile 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.file.${environment().suffixes.storage}'
  location: 'Global'
}

resource privateDnsZoneAcr 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azure.io'
  location: 'Global'
}

resource privateDnsZoneSites 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurewebsites.net'
  location: 'Global'
}

resource privateDnsZoneServiceBus 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.servicesbus.windows.net'
  location: 'Global'
}

resource privateDnsZoneKv 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.${environment().suffixes.keyvaultDns}'
  location: 'Global'
}