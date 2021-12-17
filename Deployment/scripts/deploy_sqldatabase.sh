#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

##############
# RESOURCE_GROUP_NAME
# SQL_SERVER_NAME
##############

resource_group_name=$RESOURCE_GROUP_NAME
sqlSvName=$SQL_SERVER_NAME



signed_in_user_object_id=$(az ad signed-in-user show --output json | jq -r '.objectId')
signed_in_user_display_name=$(az ad signed-in-user show --output json | jq -r '.displayName')

# SQL Database
# SQL Active Directory
az sql server ad-admin create -g $resource_group_name -s $sqlSvName -u "$signed_in_user_display_name" -i "$signed_in_user_object_id"
