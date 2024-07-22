param vnetId string
param location string = resourceGroup().location
param privateDnsZoneName string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: location
  tags: {}
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDnsZoneName}-link'
  parent: privateDnsZone
  properties: {
    registrationEnabled: true  // Optional: Set to true for automatic VM record registration
    virtualNetwork: {
      id: vnetId
    }
  }
}
