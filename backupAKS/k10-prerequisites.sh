#!/bin/bash

#prerequisites

curl https://docs.kasten.io/tools/k10_preflight.sh | bash

helm repo add kasten https://charts.kasten.io/

kubectl create namespace kasten-io