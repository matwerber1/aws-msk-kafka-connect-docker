#!/bin/bash

#----------------------------------
# EDIT FOR YOUR AWS ENVIRONMENT
#----------------------------------
S3_REGION=YOUR_S3_BUCKET_REGION
S3_BUCKET_NAME=YOUR_S3_BUCKET_NAME
CLUSTER_REGION=_YOUR_MSK_CLUSTER_REGION
CLUSTER_ARN=YOUR_MSK_CLUSTER_ARN
USE_SSL=0

#----------------------------------
# OPTIONALLY, EDIT BELOW
#----------------------------------
PRODUCER_PORT=8083
SYNC_PORT=8084
PRODUCER_TOPIC_PREFIX="producer-demo"
SYNC_TOPIC_PREFIX="s3-sync-demo"