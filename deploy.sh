#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace # For debugging

. ./Deployment/scripts/init.sh
project=linage # CONSTANT - this is prefix for this sample

for env_name in demo; do  # dev stg prod
    PROJECT=$project \
    DEPLOYMENT_ID=$DEPLOYMENT_ID \
    ENV_NAME=$env_name \
    AZURE_LOCATION=$AZURE_LOCATION \
    AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID \
    bash -c "./Deployment/scripts/deploy_infrastructure.sh"  # inclues AzDevOps Azure Service Connections and Variable Groups
done