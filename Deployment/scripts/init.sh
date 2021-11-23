#!/bin/bash


# Check if user is logged in
if [[ -n $(az account show 2> /dev/null) ]];then
    echo "user is already logged in"
else
    { echo "Please login via the Azure CLI: "; az login; }
fi

# 未設定の環境変数の設定.

DEPLOYMENT_ID=${DEPLOYMENT_ID:-}
if [ -z "$DEPLOYMENT_ID" ]
then 
    num=$(($(od -vAn --width=4 -tu4 -N4 </dev/urandom) % 1001))
    ID=$(printf "%04d" "${num}")
    export DEPLOYMENT_ID=$ID

    echo "No deployment id [DEPLOYMENT_ID] specified, defaulting to $DEPLOYMENT_ID"
fi



AZURE_LOCATION=${AZURE_LOCATION:-}
if [ -z "$AZURE_LOCATION" ]
then    
    export AZURE_LOCATION="japaneast"
    echo "No resource group location [AZURE_LOCATION] specified, defaulting to $AZURE_LOCATION"
fi


AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
if [ -z "$AZURE_SUBSCRIPTION_ID" ]
then
    export AZURE_SUBSCRIPTION_ID=$(az account show --output json | jq -r '.id')
    echo "No Azure subscription id [AZURE_SUBSCRIPTION_ID] specified. Using default subscription id."
fi


