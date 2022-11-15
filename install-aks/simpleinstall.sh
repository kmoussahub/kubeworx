#!/bin/bash
myResourceGroup=$1
name=$2

az group create --name $myResourceGroup --location westeurope

az aks create --resource-group $myResourceGroup --name $name --node-count 1 --enable-addons monitoring --generate-ssh-keys