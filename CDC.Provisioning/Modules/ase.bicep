param location string
param resourcePrefix string
param subNetId string
param zoneRedundant bool

resource ase 'Microsoft.Web/hostingEnvironments@2021-03-01' = {
  name:'${resourcePrefix}-ase'
  location: location
  kind: 'ASEV3'
  properties: {
    virtualNetwork: {
      id: subNetId
    }
    zoneRedundant: zoneRedundant
  }
}

output id string = ase.id
