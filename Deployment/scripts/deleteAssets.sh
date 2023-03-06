#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

#############################################################
# 変数
# PURVIEWACCOUNTNAME
# COLLECTIONID

purviewAccountName=$PURVIEWACCOUNTNAME
collectionId=$COLLECTIONID

##############################################################
# 定数
version='2021-05-01-preview'
baseUrl=https://${purviewAccountName}.purview.azure.com/
QueryURL=${baseUrl}catalog/api/search/query?api-version=${version}

body=$(printf '{
  "keywords": null,
  "limit": 10,
  "filter": {
    "collectionId": "%s"
  }
}'  "${collectionId}")

##############################################################
# 関数
deleteGUIDs () {
    declare json=$1

    guids=$(echo $json | jq -r '.value[].id ')
    param=''
    cnt=0
    for guid in $guids; do
        if [ $cnt = 0 ]; then
            param+='guid='${guid}
        else
            param+='&guid='${guid}
        fi
        # echo "param $param"
        # echo "guid=$guid"
        ((++cnt))
    done
    echo $param
    deleteUrl=${baseUrl}catalog/api/atlas/v2/entity/bulk?$param
    # curl -X DELETE -H "Content-Type: application/json" -H "Authorization: Bearer $token"  "$deleteUrl"
    az rest --method delete --url "$deleteUrl" --header "Content-Type=application/json" --resource "https://purview.azure.net"
}
##############################################################


respQuery=$(az rest --method POST --resource "https://purview.azure.net" --url "$QueryURL" --body "$body")

# export respQuery=$(curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $token" --data "$body" "$QueryURL")
export queryVal=$(echo $respQuery | jq  '.value[] ')
# (echo $respQuery | jq -r '.value[].id ')

# クエリが返らなくなるまで削除

while [ -n "$queryVal" ]
do
    (echo $respQuery | jq -r '.value[].id ')
    deleteGUIDs "$respQuery"
    export respQuery=$(az rest --method POST --resource "https://purview.azure.net" --url "$QueryURL" --body "$body")
    export queryVal=$(echo $respQuery | jq  '.value[] ')
    if  [ -z "$queryVal" ]; then
        echo "Exit out of loop due to break"
        break
    fi
done


PURVIEWACCOUNTNAME=$purviewAccountName \
COLLECTIONID=$collectionId \
