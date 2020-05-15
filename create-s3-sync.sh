#!/bin/bash

#-------------------------------------------------------------------------------
# Load Configuration
#-------------------------------------------------------------------------------

. config/global.sh

#-------------------------------------------------------------------------------
# Only edit if you want to customize things:
#-------------------------------------------------------------------------------

ZOOKEEPER_STRING=$(aws kafka describe-cluster --cluster-arn $CLUSTER_ARN | jq ' .ClusterInfo.ZookeeperConnectString ' --raw-output)
TLS_BROKERS=$(aws kafka get-bootstrap-brokers --region $REGION --cluster-arn $CLUSTER_ARN | jq ' .BootstrapBrokerStringTls' --raw-output)
PLAINTEXT_BROKERS=$(aws kafka get-bootstrap-brokers --region $REGION --cluster-arn $CLUSTER_ARN | jq ' .BootstrapBrokerString' --raw-output)

if [ $USE_TLS_BROKERS -eq 1 ]
then
  BROKERS=$TLS_BROKERS
else
  BROKERS=$PLAINTEXT_BROKERS
fi

# Run our Kafka Connect demo container. Note - it takes a minute or two to finish setting up. 
# Once its done, it listens on a local port and we need to curl a command to the listener to
# tell it to start producing our demo data:

if [ $USE_TLS_BROKERS -eq 1 ]
then
  # After we figure out how to do this with plaintext brokers, we'll come back to TLS...
  echo "TLS brokers not yet supported, exiting."
else
docker run -it --rm --expose $PORT -p $SYNC_PORT:$SYNC_PORT \
  --env=host \
  -e CONNECT_BOOTSTRAP_SERVERS="$BROKERS" \
  -e CONNECT_REST_HOST_NAME="0.0.0.0" \
  -e CONNECT_REST_PORT="$PORT" \
  -e CONNECT_REST_ADVERTISED_HOST_NAME="localhost" \
  -e CONNECT_REST_ADVERTISED_LISTENER="http" \
  -e CONNECT_REST_ADVERTISED_PORT="$SYNC_PORT" \
  -e CONNECT_GROUP_ID="$SYNC_TOPIC_PREFIX-group" \
  -e CONNECT_CONFIG_STORAGE_TOPIC="$SYNC_TOPIC_PREFIX-config" \
  -e CONNECT_OFFSET_STORAGE_TOPIC="$SYNC_TOPIC_PREFIX-offsets" \
  -e CONNECT_STATUS_STORAGE_TOPIC="$SYNC_TOPIC_PREFIX-status" \
  -e CONNECT_KEY_CONVERTER="io.confluent.connect.avro.AvroConverter" \
  -e CONNECT_KEY_CONVERTER_SCHEMA_REGISTRY_URL="http://localhost:8081" \
  -e CONNECT_VALUE_CONVERTER="io.confluent.connect.avro.AvroConverter" \
  -e CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL="http://localhost:8081" \
  -v ~/.aws/credentials:/root/.aws/credentials \
  confluentinc/cp-kafka-connect:5.4.2
fi

#
#  -e CONNECT_INTERNAL_KEY_CONVERTER="org.apache.kafka.connect.storage.StringConverter" \
#-e CONNECT_INTERNAL_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
