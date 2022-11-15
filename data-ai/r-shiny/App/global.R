library(RPostgreSQL)
library(DT)
library(plotly)
library(rjson)
library(pool)

pool <- dbPool(
    drv = dbDriver("PostgreSQL", max.con = 100),
    dbname = "northwind",
    host = "rshiny-pg.postgres.database.azure.com",
    user = "karim@rshiny-pg",
    password = "pass@word.123",
    idleTimeout = 3600000,
    minSize = 5
)

freight_maxmin <- c(round(dbGetQuery(pool, "SELECT MAX(freight), MIN(freight) from orders;"), 2))
freight_maxmin <- c(round(dbGetQuery(pool, "SELECT MAX(freight), MIN(freight) from orders;"), 2))

order_id_maxmin <- c(dbGetQuery(pool, "SELECT MAX(order_id), MIN(order_id) from orders;"))
order_id_maxmin <- c(dbGetQuery(pool, "SELECT MAX(order_id), MIN(order_id) from orders;"))