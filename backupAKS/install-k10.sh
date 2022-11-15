#!/bin/bash

#install k10
tid=$1
cio=$2
cs=$3
helm install k10 kasten/k10 --namespace=kasten-io \
    --set secrets.azureTenantId=$tid \
    --set secrets.azureClientId=$cio \
    --set secrets.azureClientSecret=$cs


helm install k10 kasten/k10 --namespace=kasten-io \
    --set secrets.azureTenantId=5c2d8a60-1ca0-4797-9c2c-0d65923fb46f \
    --set secrets.azureClientId=b426b0b6-778f-4385-b12c-fa387f017fac \
    --set secrets.azureClientSecret='GgLUkb]E[xXPpL@Xayk?x8fkgh3mDc44'

# install k10 on ARO 4.3
helm install k10 kasten/k10 --namespace=kasten-io \
        --set scc.create=true \
        --set secrets.azureTenantId=5c2d8a60-1ca0-4797-9c2c-0d65923fb46f \
        --set secrets.azureClientId=d76c5c69-1e92-4b6f-8714-e1dacb41e61b \
        --set secrets.azureClientSecret='gxLv2ReeS7TOsHpelcmZOBvZK1T6]//.'


