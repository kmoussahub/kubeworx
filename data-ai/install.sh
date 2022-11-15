#!/bin/bash

az group create --name rshing-rg --location westeurope

az postgres server create --resource-group rshiny-rg --name shiny-pg --location westeurope --admin-user 
karim --admin-password pass@word.123 --sku-name B_Gen5_1 --version 9.6

az postgres server firewall-rule create --resource-group rshing-rg --server rshiny-pg --name AllowMyIP 
--start-ip-address 95.60.194.185 --end-ip-address 95.60.194.185


psql --host=shiny-pg.postgres.database.azure.com --port=5432 --username=jonadmin@shiny-pg --dbname=postgres