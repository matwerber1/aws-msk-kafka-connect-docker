#!/bin/bash

# After you have started the Kafka Connect container with the Datagen Connector, 
# you can locally invoke this API to tell the connector to start producing data.
# Data will be sent to the topic "stock-trades":

# Load our config

. config/global.sh

# Start data production
curl \
  -X POST \
  -H "Content-Type: application/json" \
  --data @config/stock-trade.config \
  http://localhost:$PRODUCER_PORT/connectors