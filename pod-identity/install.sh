!#/bin/bash

kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment-rbac.yaml
az identity create -g <resourcegroup> -n <name> -o json

#aadpodidentity.yaml
cat <<EOF | kubectl apply -f -
apiVersion: "aadpodidentity.k8s.io/v1"
kind: AzureIdentity
metadata:
  name: <a-idname>
  annotations:
    aadpodidentity.k8s.io/Behavior: namespaced
spec:
  type: 0 
  ResourceID: /subscriptions/<subid>/resourcegroups/<resourcegroup>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<name>
  ClientID: <clientId>
EOF
#aadpodidneitybinding.yaml
cat <<EOF | kubectl apply -f -
apiVersion: "aadpodidentity.k8s.io/v1"
kind: AzureIdentityBinding
metadata:
  name: demo1-azure-identity-binding
spec:
  AzureIdentity: <a-idname>
  Selector: <label value to match>
EOF


az aks show -g <resourcegroup> -n <name> --query servicePrincipalProfile.clientId -o tsv
az role assignment create --role "Managed Identity Operator" --assignee <sp id> --scope <full id of the managed identity>

# remove the custom chain reference
iptables -t nat -D PREROUTING -j aad-metadata

# flush the custom chain
iptables -t nat -F aad-metadata

# remove the custom chain
iptables -t nat -X aad-metadata

There are two main components of the aad-pod-identity - MIC (Managed Identity Controller) and NMI (Node Managed Identity).
MIC keeps track of the pods that are created, deleted and updated via Kubernetes go client(client-go) cache. The client-go keeps the local cache in sync with the Kubernetes API server. When a pod gets scheduled to a node and an identity match is found via pod labels, MIC contacts Azure Resource Manager (ARM) to assign the user assigned identity to the VM/VMSS. When these pods are removed from the node, MIC will remove the user assigned identity from the underlying VM/VMSS.
NMI is responsible for redirecting all application traffic which are going to the Azure Instance Metadata Service (IMDS). NMI uses iptables on Linux to achieve this.
AAD pod identity architecture
AAD pod identity architecture
When a token request reaches NMI, it looks up the AzureAssignedIdentity cache listing to determine if there is a matching identity for the pod making the request. If there is one, it gets the token based on this identity and provides the token to the application. With this token, application can successfully access the cloud resource.