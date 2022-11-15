#!/bin/bash

az login


AZURE_BACKUP_SUBSCRIPTION_NAME=<NAME_OF_TARGET_SUBSCRIPTION>
AZURE_BACKUP_SUBSCRIPTION_ID=$(az account list --query="[?name=='$AZURE_BACKUP_SUBSCRIPTION_NAME'].id | [0]" -o tsv)

az account set -s $AZURE_BACKUP_SUBSCRIPTION_ID


AZURE_BACKUP_RESOURCE_GROUP=Velero_Backups
az group create -n $AZURE_BACKUP_RESOURCE_GROUP --location WestEurope

AZURE_STORAGE_ACCOUNT_ID="velero$(uuidgen | cut -d '-' -f5 | tr '[A-Z]' '[a-z]')"
az storage account create \
    --name $AZURE_STORAGE_ACCOUNT_ID \
    --resource-group $AZURE_BACKUP_RESOURCE_GROUP \
    --sku Standard_GRS \
    --encryption-services blob \
    --https-only true \
    --kind BlobStorage \
    --access-tier Hot

BLOB_CONTAINER=velero
az storage container create -n $BLOB_CONTAINER --public-access off --account-name $AZURE_STORAGE_ACCOUNT_ID
#AKS infrastructure RG
AZURE_RESOURCE_GROUP=MC_cloudNative_cn01_westeurope


AZURE_SUBSCRIPTION_ID=`az account list --query '[?isDefault].id' -o tsv`
AZURE_TENANT_ID=`az account list --query '[?isDefault].tenantId' -o tsv`

#incase you are using velero from a different subscription, you need to give access on both subscriptions

AZURE_CLIENT_SECRET=`az ad sp create-for-rbac --name "velero" --role "Contributor" --query 'password' -o tsv \
  [--scopes /subscriptions/$AZURE_BACKUP_SUBSCRIPTION_ID /subscriptions/$AZURE_SUBSCRIPTION_ID]`
#AKS and velero are on the same subscription 

 AZURE_CLIENT_SECRET=`az ad sp create-for-rbac --name "velero" --role "Contributor" --query 'password' -o tsv`

  AZURE_CLIENT_ID=`az ad sp list --display-name "velero" --query '[0].appId' -o tsv`

  cat << EOF  > ./credentials-velero
AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}
AZURE_TENANT_ID=${AZURE_TENANT_ID}
AZURE_CLIENT_ID=${AZURE_CLIENT_ID}
AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}
AZURE_RESOURCE_GROUP=${AZURE_RESOURCE_GROUP}
AZURE_CLOUD_NAME=AzurePublicCloud
EOF

wget https://github.com/vmware-tanzu/velero/releases/tag/v1.2.0


tar -xvf v1.2.0.tar.gz

mv velero /usr/local/bin
velero install \
    --provider azure \
    --plugins velero/velero-plugin-for-microsoft-azure:v1.0.0 \
    --bucket $BLOB_CONTAINER \
    --secret-file ./credentials-velero \
    --backup-location-config resourceGroup=$AZURE_BACKUP_RESOURCE_GROUP,storageAccount=$AZURE_STORAGE_ACCOUNT_ID #[,subscriptionId=$AZURE_BACKUP_SUBSCRIPTION_ID] \
    --snapshot-location-config apiTimeout=30 #[,resourceGroup=$AZURE_BACKUP_RESOURCE_GROUP,subscriptionId=$AZURE_BACKUP_SUBSCRIPTION_ID]


    helm install --name velero --namespace velero stable/velero
