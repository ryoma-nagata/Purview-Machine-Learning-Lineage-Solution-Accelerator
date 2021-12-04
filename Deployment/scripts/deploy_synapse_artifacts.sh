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

resource_group_name=$RESOURCE_GROUP_NAME
syn_ws_name=$SYN_WORKSPACENAME
syn_spark_name=$SYN_SPARKNAME

ImportNotebook () {
    declare name=$1
    echo "Import Synapse Notebook: $name"
    az synapse notebook import --workspace-name "$syn_ws_name" \
    --name  "${name}" --file @"./SynapseNotebooks/${name}".ipynb \
    --spark-pool-name "$syn_spark_name"
}

ImportLibrary () {
    declare name=$1
    echo "Import Library: $name to $syn_spark_name"
    az synapse spark pool update --name "$syn_spark_name" --workspace-name "$syn_ws_name" --resource-group $resource_group_name \
    --library-requirements "./Deployment/${name}.txt"
}


echo "Deploying Synapse artifacts."

# notebook

echo 'Start importing SynapseNotebooks'
ImportNotebook "01_Authenticate_to_Purview_AML" 
ImportNotebook "02_Create_ML_Lineage_Types" 
ImportNotebook "03_Create_ML_Lineage_Functions" 
ImportNotebook "04_Create_CreditRisk_Experiment" 

# library

# echo 'Start importing library'
# ImportLibrary "requirements"

echo "Completed deploying Synapse artifacts."



