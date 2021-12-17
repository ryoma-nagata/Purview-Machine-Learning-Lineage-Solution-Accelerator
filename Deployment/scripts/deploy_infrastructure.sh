#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

###################
# REQUIRED ENV VARIABLES:
#
# PROJECT
# DEPLOYMENT_ID
# ENV_NAME
# AZURE_LOCATION
# AZURE_SUBSCRIPTION_ID

#####################

#####################
# DEPLOY ARM TEMPLATE
sqlpwd=$(echo /dev/urandom | base64 | fold -w 10 | head -n 1)

# Set account to where ARM template will be deployed to
echo "Deploying to Subscription: $AZURE_SUBSCRIPTION_ID"
az account set --subscription "$AZURE_SUBSCRIPTION_ID"

# Create resource group
resource_group_name="rg-$PROJECT-$DEPLOYMENT_ID-$ENV_NAME"
echo "Creating resource group: $resource_group_name"
az group create --name "$resource_group_name" --location "$AZURE_LOCATION" --tags Environment="$ENV_NAME"

# # Retrieve User Id
signed_in_user_object_id=$(az ad signed-in-user show --output json | jq -r '.objectId')

# Validate arm template

echo "Validating deployment"
arm_output=$(az deployment group validate \
    --resource-group $resource_group_name \
    --template-file ./Deployment/infrastructure/bicep/main.bicep \
    --parameters project=$PROJECT env=$ENV_NAME deployment_id=$DEPLOYMENT_ID signed_in_user_object_id=$signed_in_user_object_id \
    sqlPassword=$sqlpwd \
    --output json)

# Deploy arm template
echo "Deploying resources into $resource_group_name"
arm_output=$(az deployment group create \
    --resource-group $resource_group_name \
    --template-file ./Deployment/infrastructure/bicep/main.bicep \
    --parameters project=$PROJECT env=$ENV_NAME deployment_id=$DEPLOYMENT_ID signed_in_user_object_id=$signed_in_user_object_id \
    sqlPassword=$sqlpwd \
    --output json)

echo "Finish deploying resources into $resource_group_name"

# ########################
echo "Deploy SQL Database"

# Deploy SQL DB

sqlsvName=$(echo "$arm_output" | jq -r '.properties.outputs.sqlsvName.value')

RESOURCE_GROUP_NAME=$resource_group_name \
SQL_SERVER_NAME=$sqlsvName \
    bash -c "./Deployment/scripts/deploy_sqldatabase.sh"

#####################
# Create a Service Principal for Purview Rest API access

echo "Creating Service principal for Purview Rest API access"

sp_stor_name="${PROJECT}-apv-${ENV_NAME}-${DEPLOYMENT_ID}-sp"
rg_id=$(az group show \
    --name "$resource_group_name" \
    --output json |
    jq -r '.id')

sp_stor_out=$(az ad sp create-for-rbac \
    --role "Reader" \
    --scopes "$rg_id" \
    --name "$sp_stor_name" \
    --output json)

echo "Created Service principal : ${sp_stor_name}"

sp_appId=$(echo $sp_stor_out | jq -r .appId)
sp_tenantId=$(echo $sp_stor_out | jq -r .tenant)
sp_secret=$(echo $sp_stor_out | jq -r .password)
sleep 30
sp_objectId=$(az ad sp show --id ${sp_appId} | jq -r .objectId)

# Deploy Purview
apv_name=$(echo "$arm_output" | jq -r '.properties.outputs.apv_name_output.value')
syn_objectId=$(echo "$arm_output" | jq -r '.properties.outputs.synapsePId.value')
synapsestorageName=$(echo "$arm_output" | jq -r '.properties.outputs.synapsestorageName.value')

RESOURCE_GROUP_NAME=$resource_group_name \
APV_NAME=$apv_name \
SP_OBJECTID=$sp_objectId \
SYNAPSE_OBJECTID=$syn_objectId \
SYNAPSE_STORAGENAME=$synapsestorageName \
SQL_SERVER_NAME=$sqlsvName \
    bash -c "./Deployment/scripts/deploy_purview.sh"


#####################


# upload data

synapsestorageName=$(echo "$arm_output" | jq -r '.properties.outputs.synapsestorageName.value')
synContainer=$(echo "$arm_output" | jq -r '.properties.outputs.synContainer.value')

echo "Uploading data to ${synapsestorageName}"

az storage blob upload-batch  \
--auth-mode login \
-d "$synContainer" \
--account-name "$synapsestorageName" \
-s ./Data

echo "Finish uploading data"



#####################

# Deploy Synapse
# リソース固有値変更


synapseSrcDir=./Deployment/template/synapse/
# synLsDir=$synTmpDir/linkedService

synWorkspaceName=$(echo "$arm_output" | jq -r '.properties.outputs.synWorkspaceName.value')
synSparkName=$(echo "$arm_output" | jq -r '.properties.outputs.synSparkName.value')

RESOURCE_GROUP_NAME=$resource_group_name \
SYN_WORKSPACENAME=$synWorkspaceName \
SYN_SPARKNAME=$synSparkName \
SYN_SRCDIR=$synapseSrcDir \
SYNAPSE_STORAGENAME=$synapsestorageName \
SQL_SERVER_NAME=$sqlsvName \
    bash -c "./Deployment/scripts/deploy_synapse_artifacts.sh"

#####################
# variables file

azuremlName=$(echo "$arm_output" | jq -r '.properties.outputs.azuremlName.value')
json=$(printf '
{
    "01_Authenticate_to_Purview_AML":{
    "TENANT_ID": "%s",
    "CLIENT_ID": "%s",
    "CLIENT_SECRET":"%s",
    "PURVIEW_NAME": "%s",
    "SUBSCRIPTION_ID": "%s",
    "RESOURCE_GROUP":"%s",
    "WORKSPACE_NAME": "%s",
    "WORKSPACE_REGION": "%s"},
    "04_Create_CreditRisk_Experiment":{
        "Synapse_Storage_Account_Name":"%s"
    }   
}' "${sp_tenantId}" "${sp_appId}" ${sp_secret} ${apv_name} ${AZURE_SUBSCRIPTION_ID} ${resource_group_name} ${azuremlName} ${AZURE_LOCATION} ${synapsestorageName})

echo "$json" | jq '.' > variable.json

# finish
echo "Completed deploying Azure resources $resource_group_name" 