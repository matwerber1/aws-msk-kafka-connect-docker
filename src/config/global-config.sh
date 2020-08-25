#!/bin/bash

#----------------------------------
# EDIT FOR YOUR AWS ENVIRONMENT
#----------------------------------
S3_REGION=us-west-2
S3_BUCKET_NAME=kafka-connect-demo
CLUSTER_REGION=us-west-2
USE_SSL=0

#----------------------------------
# OPTIONALLY, EDIT BELOW
#----------------------------------
CLOUDFORMATION_STACK_NAME=msk-kafka-connect-demo

KAFKA_CONNECT_SOURCE_PORT=8083
KAFKA_CONNECT_SINK_PORT=8084
KAFKA_CONNECT_SOURCE_TOPIC_PREFIX="kafka-connect-source-demo"
KAFKA_CONNECT_SINK_TOPIC_PREFIX="kafka-connect-sink-demo"