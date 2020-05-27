#!/bin/bash

#----------------------------------
# EDIT FOR YOUR AWS ENVIRONMENT
#----------------------------------
S3_REGION=us-west-2
S3_BUCKET_NAME=kafka-connect-demo
CLUSTER_REGION=us-west-2
CLUSTER_ARN=arn:aws:kafka:us-west-2:544941453660:cluster/msk-kafka-connect-demo-MskCluster/cb530c96-5213-4ce3-998c-752689aad19e-3
USE_SSL=0

#----------------------------------
# OPTIONALLY, EDIT BELOW
#----------------------------------
PRODUCER_PORT=8083
SYNC_PORT=8084
PRODUCER_TOPIC_PREFIX="producer-demo"
SYNC_TOPIC_PREFIX="s3-sync-demo"