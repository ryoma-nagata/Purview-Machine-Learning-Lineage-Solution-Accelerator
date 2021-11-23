

param paramName string

@allowed([
  'true'
  'false'
])
param AllowAll string = 'true'
param purviewId string


var location = resourceGroup().location

var synapseWorkspaceName_var = 'syn-ws-${paramName}'
var storageName_var = replace(replace(toLower('synst${paramName}'), '-', ''), '_', '')
var storageContainer = 'data'


//https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var StorageBlobDataContributor = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource synapsestorage 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageName_var
  location: location
  sku: {
    name: 'Standard_LRS'

  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
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
          enabled: true
        }
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}


resource storageName_default 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  parent: synapsestorage
  name: 'default'
  properties: {
    isVersioningEnabled: false
  }
  dependsOn: [
    
  ]
}

resource storageName_default_storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  parent: storageName_default
  name: storageContainer
  properties: {

    publicAccess: 'None'
  }
}


resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: synapseWorkspaceName_var
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    purviewConfiguration:{
      purviewResourceId:purviewId
    }
    defaultDataLakeStorage: {
      accountUrl: 'https://${storageName_var}.dfs.${environment().suffixes.storage}'
      filesystem: storageContainer
    }
    virtualNetworkProfile: {
      computeSubnetId: ''
    }
    sqlAdministratorLogin: 'sqladminuser'
  }
}


resource synapseWorkspace_allowAll 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = if (AllowAll == 'true') {
  parent: synapseWorkspace
  name: 'allowAll'

  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

resource synapseWorkspace_spark1 'Microsoft.Synapse/workspaces/bigDataPools@2021-06-01' = {
  parent: synapseWorkspace
  name: 'spark2x4'
  location: location
  properties: {
    sparkVersion: '2.4'
    nodeCount: 3
    nodeSize: 'Medium'
    nodeSizeFamily: 'MemoryOptimized'
    autoScale: {
      enabled: true
      minNodeCount: 3
      maxNodeCount: 6
    }
    autoPause: {
      enabled: true
      delayInMinutes: 15
    }
    isComputeIsolationEnabled: false
    sessionLevelPackagesEnabled: false
    cacheSize: 0
    dynamicExecutorAllocation: {
      enabled: true
    }
    provisioningState: 'Succeeded'
  }
}

resource roleAssignments_synapsetostorage 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: synapsestorage
  name: guid('synapseBlobContributor',synapsestorage.name)
  properties: {
    roleDefinitionId: StorageBlobDataContributor
    principalId: synapseWorkspace.identity.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn:[
    synapsestorage
    synapseWorkspace
  ]
}




output synapsestorageName string = synapsestorage.name
output synapsePId string = synapseWorkspace.identity.principalId

output synDatalakeName string = storageName_var
output synContainer string = storageContainer
output synWorkspaceName string = synapseWorkspaceName_var
output synSparkName string = 'spark2x4'
