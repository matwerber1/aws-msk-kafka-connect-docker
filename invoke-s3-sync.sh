#!/bin/bash

# Load our configuration
. config/global.sh

# Invoke S3 Sync container to start sync process from MSK to S3:
curl -X POST \
  -H "Content-Type: application/json" \
  --data @s3-sync.config \
  http://localhost:$PORT/connectors