param synapsestorageName string
param azuremlName string 
param purviewId string
param synapseId string
param synapseName string

//https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var contributor = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
var StorageBlobDataReader = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
var reader = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'

resource synapsestorage 'Microsoft.Storage/storageAccounts@2021-06-01' existing={
  name:synapsestorageName
}

resource machinelearning 'Microsoft.MachineLearningServices/workspaces@2021-07-01' existing={
  name:azuremlName
}

resource synapse 'Microsoft.Synapse/workspaces@2021-06-01' existing={
  name:synapseName
}

resource roleAssignments_purviewtostorage 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope:synapsestorage
  name: guid('purivewBlobReader',synapsestorageName)
  properties: {
    roleDefinitionId: StorageBlobDataReader
    principalId: purviewId
    principalType: 'ServicePrincipal'
  }
  dependsOn:[
    synapsestorage
  ]
}


resource roleAssignments_synapsetoAzureml 'Microsoft.Authorization/roleAssignments@2020-04-01-preview'={
  name:guid('synapseContributor',machinelearning.name)
  properties:{
    roleDefinitionId:contributor
    principalId:synapseId
    principalType: 'ServicePrincipal'
  }
  scope: machinelearning
}

resource roleAssignments_apvtosyn 'Microsoft.Authorization/roleAssignments@2020-04-01-preview'={
  name:guid('synapseContributor',synapse.name)
  properties:{
    roleDefinitionId:reader
    principalId:purviewId
    principalType: 'ServicePrincipal'
  }
  scope: synapse
}
