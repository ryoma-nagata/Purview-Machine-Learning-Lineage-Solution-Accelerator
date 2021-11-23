
param paramName string
param location string =resourceGroup().location


var purviewName = 'apv-${paramName}'

resource purview 'Microsoft.Purview/accounts@2021-07-01' = {
  name: purviewName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess:'Enabled'
  }
  tags: {}
  dependsOn: []
}

output purviewPrincipalId string = purview.identity.principalId
output purviewResourceId string = purview.id
output purviewResourceName string = purviewName
