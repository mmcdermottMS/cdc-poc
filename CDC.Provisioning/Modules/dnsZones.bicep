//https://docs.microsoft.com/en-us/azure/templates/microsoft.network/privateendpoints?tabs=bicep#privatelinkserviceconnection

resource privateDnsZoneBlob 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'Global'
}

resource privateDnsZoneFile 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.file.${environment().suffixes.storage}'
  location: 'Global'
}
