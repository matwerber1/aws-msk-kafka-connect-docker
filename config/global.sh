#!/bin/bash

# EDIT TO MATCH YOUR CONFIG
REGION="us-west-2"
CLUSTER_ARN="arn:aws:kafka:us-west-2:544941453660:cluster/my-cluster/327fed8e-e90d-439d-8477-d31fc2ce7117-3"
USE_TLS_BROKERS=0

# No need to change unless you want to:
PRODUCER_PORT=8083
SYNC_PORT=8084
PRODUCER_TOPIC_PREFIX="stock-trades"
SYNC_TOPIC_PREFIX="s3-sync"