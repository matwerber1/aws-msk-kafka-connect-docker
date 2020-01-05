#!/bin/bash

# This file runs a Kafka Connect container on the fly to communicate with our 
# Amazon MSK Cluster. For now, this container doesn't do anything interesting and 
# just demonstrates the basic bootstrapping of Kafka Connect. 

# This script must be run from a host that has network connectivity to your MSK cluster. 
# A t3.xlarge provides 16 GB ram and 4 vCPU, sufficient for testing. You might be able to 
# get away with smaller, but my JVM ran out of memory quickly on the default t2.micro Cloud9.

# This must match the CloudFormation stack name specified in the msk-cluster/deploy.sh script:
STACK_NAME="aws-msk-learning"

# Get MSK information:
HOST_ADDRESS=$(curl 169.254.169.254/latest/meta-data/hostname)
CLUSTER_ARN=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='MskClusterArn'].OutputValue" --output text)
ZOOKEEPER_STRING=$(aws kafka describe-cluster --cluster-arn $CLUSTER_ARN | jq ' .ClusterInfo.ZookeeperConnectString ' --raw-output)
# Depending on how you've configured your MSK cluster, it might have TLS and/or plaintext broker endpoints: 
TLS_BROKERS=$(aws kafka get-bootstrap-brokers --region us-east-1 --cluster-arn $CLUSTER_ARN | jq ' .BootstrapBrokerStringTls' --raw-output)
PLAINTEXT_BROKERS=$(aws kafka get-bootstrap-brokers --region us-east-1 --cluster-arn $CLUSTER_ARN | jq ' .BootstrapBrokerString' --raw-output)

# For now, we are using the plaintext brokers, as I haven't figured out how to 
# properly configure Kafka Connect for TLS encryption in transit:
CONTAINER_BROKERS=$PLAINTEXT_BROKERS

#docker container rm kafka-connect

docker run -it \
  --name=kafka-connect \
  --net=host \
  -e CONNECT_BOOTSTRAP_SERVERS="$CONTAINER_BROKERS" \
  -e CONNECT_REST_PORT=28082 \
  -e CONNECT_GROUP_ID="quickstart" \
  -e CONNECT_CONFIG_STORAGE_TOPIC="quickstart-config" \
  -e CONNECT_OFFSET_STORAGE_TOPIC="quickstart-offsets" \
  -e CONNECT_STATUS_STORAGE_TOPIC="quickstart-status" \
  -e CONNECT_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
  -e CONNECT_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
  -e CONNECT_INTERNAL_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
  -e CONNECT_INTERNAL_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
  -e CONNECT_REST_ADVERTISED_HOST_NAME="localhost" \
  -e CONNECT_PLUGIN_PATH=/usr/share/java \
  -e KAFKA_ADVERTISED_LISTENERS=$HOST_ADDRESS \
  confluentinc/cp-kafka-connect:5.3.2
