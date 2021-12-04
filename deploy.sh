#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging


project=linage # CONSTANT - this is prefix for this sample

. ./Deployment/scripts/init.sh

echo "Starting deployment at "$(date)


for env_name in demo; do  # dev stg prod
    PROJECT=$project \
    DEPLOYMENT_ID=$DEPLOYMENT_ID \
    ENV_NAME=$env_name \
    AZURE_LOCATION=$AZURE_LOCATION \
    AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID \
    bash -c "./Deployment/scripts/deploy_infrastructure.sh"  
done


echo "finish deployment at "$(date)

