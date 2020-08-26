#!/bin/bash

# Load our configuration
. config/global-config.sh

# Invoke S3 Sync container to start sync process from MSK to S3:
curl -X POST \
  -H "Content-Type: application/json" \
  --data @config/sink-connnector.config \
  http://localhost:$KAFKA_CONNECT_SINK_PORT/connectors
  

# If you need to delete a task, you can use this command: 
#curl -X DELETE localhost:$KAFKA_CONNECT_SINK_PORT/connectors/s3-sink-docker