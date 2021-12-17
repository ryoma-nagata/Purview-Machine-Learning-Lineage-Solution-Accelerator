param perviewlocation string = 'southeastasia'

param project string ='lineage'
@allowed([
  'demo'
])
param env string ='demo'
param deployment_id string 
param signed_in_user_object_id string 

@secure()
param sqlPassword string

var uniqueName = '${project}-${deployment_id}-${env}'

// 並列でデプロイするためここで生成
var purviewId = '${resourceGroup().id}/providers/Microsoft.Purview/accounts/apv-${uniqueName}'
module sql 'modules/sql.bicep' ={
  name:'sql_Deployment'
    params:{
    paramName:uniqueName
    sqlLogin:'sqladmin'
    sqlPassword:sqlPassword
  }

}

module purview 'modules/purview.bicep' = {
  name: 'Purview_Deployment'
  params: {
    location:perviewlocation
    paramName:uniqueName
  }
}
module synapse 'modules/synapse.bicep' ={
  name: 'Synapse_Deployment'
  params:{
    userId:signed_in_user_object_id
    paramName:uniqueName
    purviewId:purviewId
  }
}
module azureml 'modules/azureml.bicep' ={
  name:'Azure_ML_Deployment'
  params:{
    paramName:uniqueName
  }
}
module role 'modules/roleAssingment.bicep' ={
  name:'roleAssinment'
  params:{
    azuremlName:azureml.outputs.azuremlName
    purviewId:purview.outputs.purviewPrincipalId
    synapseId:synapse.outputs.synapsePId
    synapsestorageName:synapse.outputs.synapsestorageName
  }
  dependsOn:[
    azureml
    purview
    synapse
  ]
}

output apv_name_output string = purview.outputs.purviewResourceName
output synapsePId string = synapse.outputs.synapsePId

output synapsestorageName string = synapse.outputs.synapsestorageName
output synContainer string = synapse.outputs.synContainer
output synWorkspaceName string = synapse.outputs.synWorkspaceName
output synSparkName string = synapse.outputs.synSparkName

output azuremlName string = azureml.outputs.azuremlName
output sqlsvName string = sql.outputs.sqlserverName
