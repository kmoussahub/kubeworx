#!/bin/bash

LOCATION=westeurope
RESOURCEGROUP="v4-$LOCATION"
CLUSTER=aro2

az group create -g "$RESOURCEGROUP" -l $LOCATION
az network vnet create \
  -g "$RESOURCEGROUP" \
  -n dev-vnet \
  --address-prefixes 10.0.0.0/9 \
  >/dev/null
for subnet in "$CLUSTER-master" "$CLUSTER-worker"; do
  az network vnet subnet create \
    -g "$RESOURCEGROUP" \
    --vnet-name dev-vnet \
    -n "$subnet" \
    --address-prefixes 10.$((RANDOM & 127)).$((RANDOM & 255)).0/24 \
    --service-endpoints Microsoft.ContainerRegistry \
    >/dev/null
done
az network vnet subnet update \
  -g "$RESOURCEGROUP" \
  --vnet-name dev-vnet \
  -n "$CLUSTER-master" \
  --disable-private-link-service-network-policies true \
  >/dev/null


  #create a cluster 

  az aro create \
  -g "$RESOURCEGROUP" \
  -n "$CLUSTER" \
  --vnet dev-vnet \
  --master-subnet "$CLUSTER-master" \
  --worker-subnet "$CLUSTER-worker"
  