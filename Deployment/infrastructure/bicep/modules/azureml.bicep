

param paramName string


var location = resourceGroup().location

var machinelearningName_var = 'ml-${paramName}'
var storageMLname_var = replace(replace(toLower('mlstrg${paramName}'), '-', ''), '_', '')
var appinsightsname_var = '${machinelearningName_var}ai'
var keyvaultname_var = replace(replace(toLower('keyvault${paramName}'), '-', ''), '_', '')

resource appinsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appinsightsname_var
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    IngestionMode: 'ApplicationInsights'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource keyvault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyvaultname_var
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId:subscription().tenantId
    accessPolicies: []
    enabledForDeployment: false
    enableSoftDelete: true
    enablePurgeProtection: true
    provisioningState: 'Succeeded'
  }
}

resource storageML 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageMLname_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource machinelearning 'Microsoft.MachineLearningServices/workspaces@2021-07-01' = {
  name: machinelearningName_var
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: machinelearningName_var
    storageAccount: storageML.id
    keyVault: keyvault.id
    applicationInsights: appinsights.id
    hbiWorkspace: false
    allowPublicAccessWhenBehindVnet: false
  }
  dependsOn:[
    storageML
    keyvault
    appinsights
  ]
}



output storageMLId string = storageML.id
output azuremlName string = machinelearning.name
