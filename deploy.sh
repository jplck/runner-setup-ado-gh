#!/bin/bash

set -e

# infrastructure deployment properties
PROJECT_NAME="$1"
LOCATION="$2"
ADO_URL="$3"
ADO_PAT="$4"
ADO_POOL_NAME="$5"

if [ "$PROJECT_NAME" == "" ]; then
echo "No project name provided - aborting"
exit 0;
fi

if [ "$LOCATION" == "" ]; then
echo "No location provided - aborting"
exit 0;
fi

if [[ $PROJECT_NAME =~ ^[a-z0-9]{5,9}$ ]]; then
    echo "project name $PROJECT_NAME is valid"
else
    echo "project name $PROJECT_NAME is invalid - only numbers and lower case min 5 and max 8 characters allowed - aborting"
    exit 0;
fi

RESOURCE_GROUP="$PROJECT_NAME-rg"

AZURE_CORE_ONLY_SHOW_ERRORS="True"

az deployment sub create \
  --name "$PROJECT_NAME-core" \
  --location $LOCATION \
  --template-file ./infra/main.bicep \
  --parameters projectName=$PROJECT_NAME location=$LOCATION adoInstanceUrl=$ADO_URL adoPat=$ADO_PAT adoPoolName=$ADO_POOL_NAME
