#!/bin/bash

#----------------------------------
# EDIT FOR YOUR AWS ENVIRONMENT
#----------------------------------
S3_REGION=us-west-2
S3_BUCKET_NAME=kafka-connect-demo
CLUSTER_REGION=us-west-2
CLUSTER_ARN="arn:aws:kafka:us-west-2:544941453660:cluster/my-cluster/327fed8e-e90d-439d-8477-d31fc2ce7117-3"

# For plaintext communication with brokers, set to 0; for encrypted communication, 
# set to 1 and follow the steps in the link below to create a 'client.truststore/jks' file in the SSL folder:
#
# https://docs.aws.amazon.com/msk/latest/developerguide/msk-working-with-encryption.html
# 
# If you do use SSL, you should be able to use a command similar to below to copy your local java cacerts file
# into the ssl directory of this project (depending on your OS/java version, your source path may differ):
#
# cp /usr/lib/jvm/java-1.7.0-openjdk.x86_64/jre/lib/security/cacerts ../ssl/client.truststore.jks
USE_SSL=0

#----------------------------------
# OPTIONALLY, EDIT BELOW
#----------------------------------
PRODUCER_PORT=8083
SYNC_PORT=8084
PRODUCER_TOPIC_PREFIX="producer-demo"
SYNC_TOPIC_PREFIX="s3-sync-demo"