#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging


project=linage # CONSTANT - this is prefix for this sample

. ./Deployment/scripts/init.sh

echo "Starting deployment at "$(date)
TIME_A=`date +%s`   #A

for env_name in demo; do  # dev stg prod
    PROJECT=$project \
    DEPLOYMENT_ID=$DEPLOYMENT_ID \
    ENV_NAME=$env_name \
    AZURE_LOCATION=$AZURE_LOCATION \
    AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID \
    bash -c "./Deployment/scripts/deploy_infrastructure.sh"  # inclues AzDevOps Azure Service Connections and Variable Groups
done


echo "finish deployment at "$(date)

TIME_B=`date +%s`   #B
PT=`expr ${TIME_B} - ${TIME_A}`
H=`expr ${PT} / 3600`
PT=`expr ${PT} % 3600`
M=`expr ${PT} / 60`
S=`expr ${PT} % 60`
echo "開始: {}" 
echo "終了: {}"
echo "処理時間: ${H}:${M}:${S}"