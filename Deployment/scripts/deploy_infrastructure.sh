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
    --parameters project=$PROJECT env=$ENV_NAME deployment_id=$DEPLOYMENT_ID \
    --output json)

# Deploy arm template
echo "Deploying resources into $resource_group_name"
arm_output=$(az deployment group create \
    --resource-group $resource_group_name \
    --template-file ./Deployment/infrastructure/bicep/main.bicep \
    --parameters project=$PROJECT env=$ENV_NAME deployment_id=$DEPLOYMENT_ID \
    --output json)

echo "Finish deploying resources into $resource_group_name"

# ########################

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
sleep 30
sp_objectId=$(az ad sp show --id ${sp_appId} | jq -r .objectId)

apv_name=$(echo "$arm_output" | jq -r '.properties.outputs.apv_name_output.value')
syn_objectId=$(echo "$arm_output" | jq -r '.properties.outputs.synapsePId.value')
synapsestorageName=$(echo "$arm_output" | jq -r '.properties.outputs.synapsestorageName.value')


# Deploy Purview
RESOURCE_GROUP_NAME=$resource_group_name \
APV_NAME=$apv_name \
SP_OBJECTID=$sp_objectId \
SYNAPSE_OBJECTID=$syn_objectId \
SYNAPSE_STORAGENAME=$synapsestorageName \
    bash -c "./Deployment/scripts/deploy_purview.sh"

#####################

# Deploy Synapse

synWorkspaceName=$(echo "$arm_output" | jq -r '.properties.outputs.synWorkspaceName.value')
synSparkName=$(echo "$arm_output" | jq -r '.properties.outputs.synSparkName.value')

RESOURCE_GROUP_NAME=$resource_group_name \
SYN_WORKSPACENAME=$synWorkspaceName \
SYN_SPARKNAME=$synSparkName \
    bash -c "./Deployment/scripts/deploy_synapse_artifacts.sh"


echo "Completed deploying Azure resources $resource_group_name "