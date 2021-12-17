#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

##############


# # REQUIRED ENV VARIABLES:
# APV_NAME
# RESOURCE_GROUP_NAME
# SP_OBJECTID
# SYNAPSE_OBJECTID
# SYNAPSE_STORAGENAME
# SQL_SERVER_NAME

##############




apv_name=$APV_NAME
resource_group_name=$RESOURCE_GROUP_NAME
sp_objectId=$SP_OBJECTID
addMemberPID=$SYNAPSE_OBJECTID
synapsestorageName=$SYNAPSE_STORAGENAME
sqlsvName=$SQL_SERVER_NAME

topCollectionName='localdev'

##############
# variable

endpoint="https://${apv_name}.purview.azure.com"

##############
# functions

CreateCollection () {
    declare collectionName=$1
    declare parentFrendryName=$2
    getCollectionURL=${endpoint}/collections/${parentFrendryName}?api-version=2019-11-01-preview
    parentCollectionName=$(az rest --method get --resource "https://purview.azure.net" --url $getCollectionURL | jq -r '.name')
    createColleciontURL=${endpoint}/collections/${collectionName}?api-version=2019-11-01-preview
    collectionBody=$(printf '
        {
            "parentCollection": {
                "referenceName":"%s"
            }
        }
    ' "${parentCollectionName}")
    az rest --method put --resource "https://purview.azure.net" --url $createColleciontURL --body "$collectionBody"
    echo "Created Collection: $collectionName"
}

CreateKeyVault () {
    declare keyVaultName=$1
    createKeyVaultURL=${endpoint}/scan/azureKeyVaults/${keyVaultName}?api-version=2018-12-01-preview
    KeyVaultBody=$(printf '
        {
            "properties": {
                "baseUrl": "https://%s.vault.azure.net/",
                "description": "Governance KeyVault"
            }
        }
    ' "${keyVaultName}")
    az rest --method put --resource "https://purview.azure.net" --url $createKeyVaultURL --body "$KeyVaultBody"
    echo "Created KeyVault Connection: $keyVaultName"
}

##############

echo "Deploying Purview"

# Step 2. Purview Security Access

# Step 2.2 Configure your Purview catalog to trust the service principal
# Configure your Purview catalog to trust the service principal

# base_url=https://management.azure.com
# purview_id=$(az purview account show --name ${apv_name} --resource-group ${resource_group_name} | jq -r '.id')
# version='2021-07-01'
# restUrl=${base_url}${purview_id}/addRootCollectionAdmin?api-version=${version}
# body="{\"objectId\":\"${sp_objectId}\"}"

# az rest --method post --url $restUrl --body $body
# echo '$sp_objectId is assigned Root Collection Administorator'

# az rest --method get --resource "https://purview.azure.net" --url $restUrl


# Configure DataCurator role menber add synapse id and service principal
version='2021-07-01'
getColURL=https://${apv_name}.purview.azure.com/policystore/collections/${apv_name}/metadataPolicy?api-version=${version}

echo "get collections"
resp=$(az rest --method get --resource "https://purview.azure.net" --url $getColURL)

# collectionId
collectionId=$(echo $resp | jq -r '.id')

# policyテンプレート
echo "create policy"
policy=$(echo $resp | jq '. | .properties.attributeRules |= .-.')
# curatorのロール部分
rulename_curator=purviewmetadatarole_builtin_data-curator:${apv_name}
rulename_col_admin=purviewmetadatarole_builtin_collection-administrator:${apv_name}
rulename_reader=purviewmetadatarole_builtin_purview-reader:${apv_name}
rulename_ds_admin=purviewmetadatarole_builtin_data-source-administrator:${apv_name}
rulename_permission=permission:${apv_name}

attributeRules_curator=$(echo $resp | jq --arg ruleName "$rulename_curator" '.properties.attributeRules[] | select(.name == $ruleName) ')
attributeRules_col_admin=$(echo $resp | jq --arg ruleName "$rulename_col_admin" '.properties.attributeRules[] | select(.name == $ruleName) ')
attributeRules_reader=$(echo $resp | jq --arg ruleName "$rulename_reader" '.properties.attributeRules[] | select(.name == $ruleName) ')
attributeRules_ds_admin=$(echo $resp | jq --arg ruleName "$rulename_ds_admin" '.properties.attributeRules[] | select(.name == $ruleName) ')
attributeRules_permission=$(echo $resp | jq --arg ruleName "$rulename_permission" '.properties.attributeRules[] | select(.name == $ruleName) ')


# attributeRules_curator初期化
attributeRules_dnfEmp=$(echo $resp | jq --arg ruleName "$rulename_curator" '.properties.attributeRules[] | select(.name == $ruleName) | .dnfCondition[] |= .-.')



echo "add menber"
# member 追加
# synapse
principalMSid=$(echo $attributeRules_curator | jq --arg addMemberPID "$addMemberPID" '.dnfCondition[][] | select(.attributeName == "principal.microsoft.id")  | .attributeValueIncludedIn |= .+[$addMemberPID]')
# service principal
principalMSid=$(echo $principalMSid | jq --arg addMemberPID "$sp_objectId" '.attributeValueIncludedIn |= .+[$addMemberPID]')

# (echo $principalMSid | jq '.')

# derivedPvRole復元
derivedPvRole=$(echo $attributeRules_curator | jq '.dnfCondition[][] | select(.attributeName == "derived.purview.role") ')

# 追加
attributeRules_curator=$(echo $attributeRules_dnfEmp | jq --argjson principalMSid "$principalMSid" '. | .dnfCondition[] |= .+[$principalMSid]')
attributeRules_curator=$(echo $attributeRules_curator | jq --argjson derivedPvRole "$derivedPvRole" '. | .dnfCondition[] |= .+[$derivedPvRole]')

(echo $attributeRules_curator | jq '.')
# create body

body=$(echo $policy | jq   --argjson attributeRules "$attributeRules_curator" '. | .properties.attributeRules |= .+[$attributeRules]')
body=$(echo $body | jq   --argjson attributeRules "$attributeRules_col_admin" '. | .properties.attributeRules |= .+[$attributeRules]')
body=$(echo $body | jq   --argjson attributeRules "$attributeRules_reader" '. | .properties.attributeRules |= .+[$attributeRules]')
body=$(echo $body | jq   --argjson attributeRules "$attributeRules_ds_admin" '. | .properties.attributeRules |= .+[$attributeRules]')
body=$(echo $body | jq   --argjson attributeRules "$attributeRules_permission" '. | .properties.attributeRules |= .+[$attributeRules]')

# (echo $body | jq '.')

putUrl=https://${apv_name}.purview.azure.com/policystore/metadataPolicies/${collectionId}?api-version=${version}

az rest --method put --resource "https://purview.azure.net" --url $putUrl --body "$body"

echo "Added menber to Purview Data Curator : $principalMSid,$addMemberPID"




# Create Collection

CreateCollection $topCollectionName "$apv_name"



# Create source adls gen2

echo "Registring Data Source ADLS2"

# https://docs.microsoft.com/en-us/rest/api/purview/scanningdataplane/data-sources/create-or-update#uri-parameters

endpoint=https://${synapsestorageName}.dfs.core.windows.net/
sourcebody=$(cat ./Deployment/template/purview/source/source_adls2.json | jq --arg endpoint "$endpoint" '.properties.endpoint = $endpoint')
sourcebody=$(echo $sourcebody | jq --arg refName "$topCollectionName" '.properties.collection.referenceName = $refName')
sourcePutUrl=https://${apv_name}.scan.purview.azure.com/datasources/${synapsestorageName}?api-version=2018-12-01-preview

az rest --method put --resource "https://purview.azure.net" --url "$sourcePutUrl" --body "$sourcebody"


echo "Finish register Data Source : ${synapsestorageName} "

serverEndpoint="${sqlsvName}.database.windows.net"
sourcebody=$(cat ./Deployment/template/purview/source/source_AdventureWorksLT.json | jq --arg serverEndpoint "$serverEndpoint" '.properties.serverEndpoint = $serverEndpoint')
sourcebody=$(echo $sourcebody | jq --arg resourceName "$sqlsvName" '.properties.resourceName = $resourceName')
sourcebody=$(echo $sourcebody | jq --arg refName "$topCollectionName" '.properties.collection.referenceName = $refName')
sourcePutUrl=https://${apv_name}.scan.purview.azure.com/datasources/${sqlsvName}?api-version=2018-12-01-preview

az rest --method put --resource "https://purview.azure.net" --url $sourcePutUrl --body "$sourcebody"

echo "Finish register Data Source : ${sqlsvName} "


# Create scan adls gen2
echo "Creating Scan ADLS2"

scanPutUrl=https://${apv_name}.purview.azure.com/scan/datasources/${synapsestorageName}/scans/Scan-adls2?api-version=2018-12-01-preview
scanbody=$(cat ./Deployment/template/purview/scan/scan_adls2.json | jq --arg refName "$topCollectionName" '.properties.collection.referenceName = $refName')
az rest --method put --resource "https://purview.azure.net" --url $scanPutUrl --body "$scanbody"

echo "Created Scan ADLS2"

echo "Creating Scan AdventureWorksLT"

scanPutUrl=https://${apv_name}.purview.azure.com/scan/datasources/${sqlsvName}/scans/Scan-AdventureWorksLT?api-version=2018-12-01-preview
scanbody=$(cat ./Deployment/template/purview/scan/scan_AdventureWorksLT.json | jq --arg serverEndpoint "$serverEndpoint" '.properties.serverEndpoint = $serverEndpoint')
scanbody=$(echo $scanbody | jq --arg refName "$topCollectionName" '.properties.collection.referenceName = $refName')

az rest --method put --resource "https://purview.azure.net" --url $scanPutUrl --body "$scanbody"

echo "Created Scan AdventureWorksLT"

# run
# echo "Run Scan ADLS2"

# runScanPutUrl=https://${apv_name}.purview.azure.com/scan/datasources/${synapsestorageName}/scans/Scan-adls2/run?api-version=2018-12-01-preview
# runbody=$(printf '{"scanLevel":"Full"}')

# az rest --method post --resource "https://purview.azure.net" --url $runScanPutUrl --body "$runbody"

echo "Purview Deployment Complete"