#!/bin/bash


set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

##############
# # REQUIRED ENV VARIABLES:
# RESOURCE_GROUP_NAME 
# SYN_WORKSPACENAME 
# SYN_SPARKNAME 
# SYN_SRCDIR
# SYNAPSE_STORAGENAME
# SQL_SERVER_NAME

resource_group_name=$RESOURCE_GROUP_NAME
syn_ws_name=$SYN_WORKSPACENAME
syn_spark_name=$SYN_SPARKNAME
synapseSrcDir=$SYN_SRCDIR
dlsstorage_name=$SYNAPSE_STORAGENAME
sqlsvName=$SQL_SERVER_NAME

synBaseUrl="https://${syn_ws_name}.dev.azuresynapse.net"
synapseResource="https://dev.azuresynapse.net"
synTmpDir=.tmp/synapse

ImportNotebook () {
    declare name=$1
    echo "Import Synapse Notebook: $name"
    az synapse notebook import --workspace-name "$syn_ws_name" \
    --name  "${name}" --file @"${synTmpDir}"/notebook/${name}.ipynb \
    --spark-pool-name "$syn_spark_name"
}

ImportLibrary () {
    declare name=$1
    echo "Import Library: $name to $syn_spark_name"
    az synapse spark pool update --name "$syn_spark_name" --workspace-name "$syn_ws_name" --resource-group $resource_group_name \
    --library-requirements "${synTmpDir}"/library/${name}.txt
}

createLinkedService () {
    declare name=$1
    echo "Creating Synapse LinkedService: $name"
    az synapse linked-service create --workspace-name $syn_ws_name --name "${name}" --file @"${synTmpDir}"/linkedService/"${name}".json
}
createDataset () {
    declare name=$1
    echo "Creating Synapse Dataset: $name"
    az synapse dataset create --workspace-name $syn_ws_name --name "${name}" --file @"${synTmpDir}"/dataset/"${name}".json
}

createPipeline () {
    declare name=$1
    echo "Creating Synapse Pipeline: $name"
    # az synapse pipeline create --workspace-name $syn_ws_name --name "${name}" --file @"${SYN_DIR}"/pipeilne/"${name}".json #notwork
    body=$(jq . "${synTmpDir}"/pipeline/"${name}".json )
    synPUrl="${synBaseUrl}/pipelines/${name}?api-version=2020-12-01"
    
    az rest --method put --resource ${synapseResource} --url "${synPUrl}" --body "$body" --subscription $AZURE_SUBSCRIPTION_ID

    echo "Created Synapse Pipeline: $name"
}

createTrigger () {
    declare name=$1
    echo "Creating Synapse Trigger: $name"
    synTUrl="${synBaseUrl}/triggers/${name}?api-version=${apiVersion}"
    az rest --method put --uri "$synTUrl" --body @"${synTmpDir}"/trigger/"${name}".json
}

createDataflow () {
    declare name=$1
    echo "Creating Synapse Dataflow: $name"
    az synapse data-flow create --workspace-name $syn_ws_name --name "${name}" --file @"${synTmpDir}"/dataflow/"${name}".json
}

fixDefaulstStorageDataset () {
    declare name=$1
    echo "fix Synapse Dataset: $name"
    jq --arg ls_name "$WorkspaceDefaultStorage_lsname" '.properties.linkedServiceName.referenceName = $ls_name'  "${synTmpDir}/dataset/${name}.json" > "$tmpfile" && mv "$tmpfile" "${synTmpDir}/dataset/${name}.json"
}

#############################
echo "Deploying Synapse artifacts."


# rm $synTmpDir -r
mkdir -p $synTmpDir && cp -a $synapseSrcDir .tmp/

tmpfile=.tmpfile

WorkspaceDefaultStorage_lsname="${syn_ws_name}-WorkspaceDefaultStorage"
datalakeUrl="https://$dlsstorage_name.dfs.core.windows.net"
jq --arg ls_name "$WorkspaceDefaultStorage_lsname" '.name = $ls_name' "${synTmpDir}"/linkedService/WorkspaceDefaultStorage.json > "$tmpfile" && mv "$tmpfile" "${synTmpDir}"/linkedService/"${WorkspaceDefaultStorage_lsname}".json
jq --arg datalakeUrl "https://$dlsstorage_name.dfs.core.windows.net" '.properties.typeProperties.url = $datalakeUrl' "${synTmpDir}"/linkedService/"${WorkspaceDefaultStorage_lsname}".json > "$tmpfile" && mv "$tmpfile" "${synTmpDir}"/linkedService/"${WorkspaceDefaultStorage_lsname}".json

jq --arg sqlConString "integrated security=False;encrypt=True;connection timeout=30;data source=${sqlsvName}.database.windows.net;initial catalog=AdventureWorksLT" '.properties.typeProperties.connectionString = $sqlConString' "${synTmpDir}"/linkedService/sql_AdventureWorksLT.json > "$tmpfile" && mv "$tmpfile" "${synTmpDir}"/linkedService/sql_AdventureWorksLT.json


# # Deploy all Linked Services
# createLinkedService "Github"
# createLinkedService "sql_AdventureWorksLT"


# # Deploy all Datasets

# fixDefaulstStorageDataset datalake_bin_movies
# fixDefaulstStorageDataset datalake_csv_movies

# createDataset "github_Movies"
# createDataset "datalake_bin_movies"
# createDataset "datalake_csv_movies"

# # Deploy all Dataflows
# synDfDir=$synTmpDir/dataflow
# echo "fix Synapse Dataflow"
# jq --arg ls_name "$WorkspaceDefaultStorage_lsname" '.properties.typeProperties.sinks[0].linkedService.referenceName = $ls_name'  "$synTmpDir/dataflow/movies_new.json" > "$tmpfile" && mv "$tmpfile" "$synTmpDir/dataflow/movies_new.json"
# jq --arg ls_name "$WorkspaceDefaultStorage_lsname" '.properties.typeProperties.sources[0].linkedService.referenceName = $ls_name'  "$synTmpDir/dataflow/movies_clean.json" > "$tmpfile" && mv "$tmpfile" "$synTmpDir/dataflow/movies_clean.json"
# jq --arg ls_name "$WorkspaceDefaultStorage_lsname" '.properties.typeProperties.sinks[0].linkedService.referenceName = $ls_name'  "$synTmpDir/dataflow/movies_clean.json" > "$tmpfile" && mv "$tmpfile" "$synTmpDir/dataflow/movies_clean.json"
# jq --arg ls_name "$WorkspaceDefaultStorage_lsname" '.properties.typeProperties.sinks[0].linkedService.referenceName = $ls_name'  "$synTmpDir/dataflow/movies_upsert.json" > "$tmpfile" && mv "$tmpfile" "$synTmpDir/dataflow/movies_upsert.json"


# createDataflow movies_new
# createDataflow movies_clean
# createDataflow movies_upsert

# # Deploy all Pipelines
# createPipeline MoviesImportData
# createPipeline MoviesUpsertData

# # notebook

# echo 'Start importing SynapseNotebooks'
# ImportNotebook "01_Authenticate_to_Purview_AML" 
# ImportNotebook "02_Create_ML_Lineage_Types" 
# ImportNotebook "03_Create_ML_Lineage_Functions" 
# ImportNotebook "04_Create_CreditRisk_Experiment" 

# #############################




# # library
# # 解消されたらコメントアウトを削除する
# echo 'Start importing library'
# ImportLibrary "requirements"

# echo "Completed deploying Synapse artifacts."



