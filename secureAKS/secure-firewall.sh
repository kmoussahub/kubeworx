#!/bin/bash

#fill in the variables

sudo apt-get install jq -y 

CLUSTER_NAME=$1
QUERYRESULT=$(az aks list --query "[?name=='$CLUSTER_NAME'].{rg:resourceGroup, id:id, loc:location, vnet:agentPoolProfiles[].vnetSubnetId, ver:kubernetesVersion, svpid: servicePrincipalProfile.clientId}" -o json)
SUBSCRIPTION_ID=$(echo $QUERYRESULT | jq '.[0] .id' | grep -oP '(?<=/subscriptions/).*?(?=/)')
CLUSTER_RG=$(echo $QUERYRESULT | jq '.[0] .rg')
LOCATION=$(echo $QUERYRESULT | jq '.[0] .loc')
KUBE_VNET_NAME=$(echo $QUERYRESULT | jq '.[0] .vnet[0]' | grep -oP '(?<=/virtualNetworks/).*?(?=/)')
KUBE_FW_SUBNET_NAME="AzureFirewallSubnet" # this you cannot change
KUBE_ING_SUBNET_NAME="ingress-subnet" # here enter the name of your ingress subnet
KUBE_AGENT_SUBNET_NAME=$(echo $QUERYRESULT | jq '.[0] .vnet[0]' | grep -oP '(?<=/subnets/).*?(?=")')
FW_NAME=$2
# az network firewall list --query "[?name=='kubenetfw'].{ip:ipConfigurations[].publicIpAddress.id}"
FW_IP_NAME=$3 
KUBE_VERSION=$(echo $QUERYRESULT | jq '.[0] .ver') 
SERVICE_PRINCIPAL_ID=$(echo $QUERYRESULT | jq '.[0] .svpid')
#SERVICE_PRINCIPAL_SECRET= # here enter the service principal secret

echo $QUERYRESULT
echo $KUBE_VERSION
echo $SERVICE_PRINCIPAL_ID

az account set --subscription $SUBSCRIPTION_ID
AKS_MC_RG=$(az group list --query "[?starts_with(name, 'MC_${CLUSTER_RG}')].name | [0]" --output tsv)
az role assignment create --role "Virtual Machine Contributor" --assignee $SERVICE_PRINCIPAL_ID -g $AKS_MC_RG

az network vnet subnet create -g $CLUSTER_RG --vnet-name $KUBE_VNET_NAME

az feature register --name AKSLockingDownEgressPreview --namespace Microsoft.ContainerService

az provider register --namespace Microsoft.ContainerService 

KUBE_AGENT_SUBNET_ID=$(echo $QUERYRESULT | jq '.[0] .vnet[0]')
#kubnet plugin
#az aks create --resource-group $resourceGroup --name $CLUSTER_NAME --node-count 2 --network-plugin kubenet --vnet-subnet-id $KUBE_AGENT_SUBNET_ID --docker-bridge-address 172.17.0.1/16 --dns-service-ip 10.2.0.10 --service-cidr 10.2.0.0/24 --client-secret $SERVICE_PRINCIPAL_SECRET --service-principal $SERVICE_PRINCIPAL_ID --kubernetes-version $KUBE_VERSION --no-ssh-key
az extension add --name azure-firewall

FW_ROUTE_NAME="${FW_NAME}_fw_r"
#FW_PRIVATE_IP="10.0.3.4"

ROUTE_TABLE_ID=$(az network route-table list -g ${AKS_MC_RG} --query "[].id | [0]" -o tsv)
ROUTE_TABLE_NAME=$(az network route-table list -g ${AKS_MC_RG} --query "[].name | [0]" -o tsv)
AKS_NODE_NSG=$(az network nsg list -g ${AKS_MC_RG} --query "[].id | [0]" -o tsv)
az network vnet subnet update --resource-group $KUBE_GROUP --route-table $ROUTE_TABLE_ID --network-security-group $AKS_NODE_NSG --ids $KUBE_AGENT_SUBNET_ID
az network route-table route create --resource-group $AKS_MC_RG --name $FW_ROUTE_NAME --route-table-name $ROUTE_TABLE_NAME --address-prefix 0.0.0.0/0 --next-hop-type VirtualAppliance --next-hop-ip-address $FW_PRIVATE_IP --subscription $SUBSCRIPTION_ID

#cni plugin
#az aks create --resource-group $KUBE_GROUP --name $KUBE_NAME --node-count 2  --network-plugin azure --vnet-subnet-id $KUBE_AGENT_SUBNET_ID --docker-bridge-address 172.17.0.1/16 --dns-service-ip 10.2.0.10 --service-cidr 10.2.0.0/24 --client-secret $SERVICE_PRINCIPAL_SECRET --service-principal $SERVICE_PRINCIPAL_ID --kubernetes-version $KUBE_VERSION --no-ssh-key

FW_ROUTE_TABLE_NAME="${FW_NAME}_fw_rt"

FW_PUBLIC_IP=$(az network public-ip show -g $KUBE_GROUP -n $FW_IP_NAME --query ipAddress)
FW_PRIVATE_IP="10.0.3.4"
az network route-table create -g $KUBE_GROUP --name $FW_ROUTE_TABLE_NAME
az network vnet subnet update --resource-group $KUBE_GROUP --route-table $FW_ROUTE_TABLE_NAME --ids $KUBE_AGENT_SUBNET_ID
az network route-table route create --resource-group $KUBE_GROUP --name $FW_ROUTE_NAME --route-table-name $FW_ROUTE_TABLE_NAME --address-prefix 0.0.0.0/0 --next-hop-type VirtualAppliance --next-hop-ip-address $FW_PRIVATE_IP --subscription $SUBSCRIPTION_ID

HCP_IP=$(kubectl get endpoints -o=jsonpath='{.items[?(@.metadata.name == "kubernetes")].subsets[].addresses[].ip}')

az extension add --name azure-firewall
az network firewall network-rule create --firewall-name $FW_NAME --collection-name "aksnetwork" --destination-addresses "$HCP_IP"  --destination-ports 22 443 9000 --name "allow network" --protocols "TCP" --resource-group $KUBE_GROUP --source-addresses "*" --action "Allow" --description "aks network rule" --priority 100

az network firewall application-rule create  --firewall-name $FW_NAME --collection-name "aksbasics" --name "allow network" --protocols http=80 https=443 --source-addresses "*" --resource-group $KUBE_GROUP --action "Allow" --target-fqdns "*.azmk8s.io" "aksrepos.azurecr.io" "*.blob.core.windows.net" "mcr.microsoft.com" "*.cdn.mscr.io" "management.azure.com" "login.microsoftonline.com" "api.snapcraft.io" "*auth.docker.io" "*cloudflare.docker.io" "*cloudflare.docker.com" "*registry-1.docker.io" --priority 100

az network firewall application-rule create  --firewall-name $FW_NAME --collection-name "akstools" --name "allow network" --protocols http=80 https=443 --source-addresses "*" --resource-group $KUBE_GROUP --action "Allow" --target-fqdns "download.opensuse.org" "packages.microsoft.com" "dc.services.visualstudio.com" "*.opinsights.azure.com" "*.monitoring.azure.com" "gov-prod-policy-data.trafficmanager.net" "apt.dockerproject.org" "nvidia.github.io" --priority 101
az network firewall application-rule create  --firewall-name $FW_NAME --collection-name "osupdates" --name "allow network" --protocols http=80 https=443 --source-addresses "*" --resource-group $KUBE_GROUP --action "Allow" --target-fqdns "download.opensuse.org" "*.ubuntu.com" "packages.microsoft.com" "snapcraft.io" "api.snapcraft.io"  --priority 102

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: centos
spec:
  containers:
  - name: centoss
    image: centos
    ports:
    - containerPort: 80
    command:
    - sleep
    - "3600"
EOF

kubectl run nginx --image=nginx --port=80
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nginx-internal
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
    service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "ing-4-subnet"
spec:
  type: LoadBalancer
  loadBalancerIP: 10.0.4.4
  ports:
  - port: 80
  selector:
    run: nginx
EOF

SERVICE_IP=$(kubectl get svc nginx-internal --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
az network firewall nat-rule create  --firewall-name $FW_NAME --collection-name "inboundlbrules" --name "allow inbound load balancers" --protocols "TCP" --source-addresses "*" --resource-group $KUBE_GROUP --action "Dnat"  --destination-addresses $FW_PUBLIC_IP --destination-ports 80 --translated-address $SERVICE_IP --translated-port "80"  --priority 101

