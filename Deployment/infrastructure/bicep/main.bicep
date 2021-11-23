param perviewlocation string = 'southeastasia'

param project string ='analytics'
@allowed([
  'demo'
])
param env string ='demo'
param deployment_id string 
var uniqueName = '${project}-${deployment_id}-${env}'

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
    paramName:uniqueName
    purviewId:purview.outputs.purviewResourceId
  }
  dependsOn:[
    purview
  ]
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
