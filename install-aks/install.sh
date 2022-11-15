#!/bin/bash
myVnet=$1
myResourceGroup=$2
name=$3
sudo apt-get install jq -y 
az group create --name $myResourceGroup --location westeurope
# create Vnet 
az network vnet create \
  --name $myVnet \
  --resource-group $myResourceGroup 
az ad sp create-for-rbac --skip-assignment -o json > auth.json
appId=$(jq -r ".appId" auth.json)
password=$(jq -r ".password" auth.json)

objectId=$(az ad sp show --id $appId --query "objectId" -o tsv)

output=$(az ad sp create-for-rbac --skip-assignment --name $1)

cat <<EOF > parameters.json
{
  "aksServicePrincipalAppId": { "value": "$appId" },
  "aksServicePrincipalClientSecret": { "value": "$password" },
  "aksServicePrincipalObjectId": { "value": "$objectId" },
  "aksEnableRBAC": { "value": false }
}
EOF
SPS=$(echo $output | jq '.appId')
PASS=$(echo $output | jq '.password')
appId=$(echo $output | jq '.appId')
az role assignment create --role "Virtual Machine Contributor" --assignee $appId -g $myResourceGroup

# create subnets for AKS,firewall, ingress contnroller 
az network vnet subnet create -g $myResourceGroup --vnet-name $myVnet -n Agents-subnet --address-prefix 10.0.5.0/24 --service-endpoints Microsoft.Sql Microsoft.AzureCosmosDB Microsoft.KeyVault Microsoft.Storage
# get subnetid
subnetid="/subscriptions/78bd8a20-bb09-4c10-9d82-d88b45674c66/resourceGroups/$myResourceGroup/providers/Microsoft.Network/virtualNetworks/$myVnet/subnets/Agents-subnet"
az network vnet subnet create -g $myResourceGroup --vnet-name $myVnet -n Firewall-subnet --address-prefix 10.0.3.0/24
az network vnet subnet create -g $myResourceGroup --vnet-name $myVnet -n Ingress-subnet --address-prefix 10.0.4.0/24


    
# create cluster
az aks create \
--resource-group $myResourceGroup \
--name $name \
--node-count 2  \
--network-plugin azure \
--vnet-subnet-id $subnetid \
--docker-bridge-address 172.17.0.1/16 \
--dns-service-ip 10.2.0.10 \
--service-cidr 10.2.0.0/24 \
--client-secret $PASS \
--service-principal $SPS \
--kubernetes-version 1.14.8 \
--no-ssh-key
