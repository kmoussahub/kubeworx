#!/bin/bash
az aks delete -n $1 -g $3 -y --no-wait
az network vnet delete -n $2 -g $3
az group delete -n $3 -y
