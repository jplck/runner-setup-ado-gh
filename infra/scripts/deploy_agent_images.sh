#!/bin/bash

set -e

REGISTRY_NAME="$1"
SUB="$2"
IMAGE_NAME="$3"
DOCKERFILE="$4"

# check if registry exists in azure and return a boolean
function check_registry_exists() {
  local registry_name="$1"
  local exists=$(az acr check-name --name $registry_name --query nameAvailable --output tsv)
  echo $exists
}

while [ $(check_registry_exists $REGISTRY_NAME) == "true" ]; 
do
  echo "Registry $REGISTRY_NAME not found. Retrying in 5 seconds..."
  sleep 5
done

az acr build --subscription $SUB --registry $REGISTRY_NAME --image $IMAGE_NAME --file $DOCKERFILE .
