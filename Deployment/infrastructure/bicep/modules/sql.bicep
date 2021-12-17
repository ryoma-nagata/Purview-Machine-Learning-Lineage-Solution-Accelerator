param paramName string
param location string =resourceGroup().location
param sqlLogin string
@secure()
param sqlPassword string


var sqlserverName = 'sql-${paramName}'
var sqldbName = 'AdventureWorksLT'

resource sqlserver 'Microsoft.Sql/servers@2021-05-01-preview' = {
  name: sqlserverName
  location: location
  properties: {
    administratorLogin: sqlLogin
    administratorLoginPassword: sqlPassword

    publicNetworkAccess: 'Enabled'
  }
}

resource network 'Microsoft.Sql/servers/firewallRules@2021-05-01-preview' = {
  name:'AllowAllWindowsAzureIps'
  parent:sqlserver
  properties:{
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}
    

resource sqldatabase 'Microsoft.Sql/servers/databases@2021-05-01-preview' = {
  name: sqldbName
  location: location
  sku: {
    name: 'GP_S_Gen5_1'
    tier: 'GeneralPurpose'
  }
  parent: sqlserver
  properties: {
    autoPauseDelay: 60
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 34359738368
    minCapacity:'0.5'
    sampleName: 'AdventureWorksLT'   
  }
}

output sqlserverName string = sqlserverName
