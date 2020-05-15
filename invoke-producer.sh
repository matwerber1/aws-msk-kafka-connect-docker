#!/bin/bash

# After you have started the Kafka Connect container with the Datagen Connector, 
# you can locally invoke this API to tell the connector to start producing data.
# Data will be sent to the topic "stock-trades":

curl \
  -X POST \
  -H "Content-Type: application/json" \
  --data @config/connector_stock_trades.config \
  http://localhost:8083/connectors