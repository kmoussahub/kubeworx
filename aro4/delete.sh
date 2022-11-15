#!/bin/bash

az aro delete -g "$RESOURCEGROUP" -n "$CLUSTER"

# (optionally)
for subnet in "$CLUSTER-master" "$CLUSTER-worker"; do
  az network vnet subnet delete -g "$RESOURCEGROUP" --vnet-name dev-vnet -n "$subnet"
done
