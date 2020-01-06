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
#HOST_ADDRESS=$(curl 169.254.169.254/latest/meta-data/hostname)
CLUSTER_ARN=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='MskClusterArn'].OutputValue" --output text)
ZOOKEEPER_STRING=$(aws kafka describe-cluster --cluster-arn $CLUSTER_ARN | jq ' .ClusterInfo.ZookeeperConnectString ' --raw-output)
# Depending on how you've configured your MSK cluster, it might have TLS and/or plaintext broker endpoints:
TLS_BROKERS=$(aws kafka get-bootstrap-brokers --region us-east-1 --cluster-arn $CLUSTER_ARN | jq ' .BootstrapBrokerStringTls' --raw-output)
PLAINTEXT_BROKERS=$(aws kafka get-bootstrap-brokers --region us-east-1 --cluster-arn $CLUSTER_ARN | jq ' .BootstrapBrokerString' --raw-output)

# For now, we are using the plaintext brokers, as I haven't figured out how to
# properly configure Kafka Connect for TLS encryption in transit:
CONTAINER_BROKERS=$PLAINTEXT_BROKERS

# Before we start our datagen container, we generate the command needed to later
# subscribe to the topic that it will send sample data, so that we can see the 
# data generated: 
echo "Generating consumer.sh script that you can later use to view generated data..."
cat <<EOT > $CURRENT_DIR/consumer.sh
$KAFKA_DIR/bin/kafka-console-consumer.sh \
  --bootstrap-server $CONTAINER_BROKERS \
  --topic stock-trades --from-beginning
EOT

chmod 777 $CURRENT_DIR/consumer.sh

# If we already had a similarly-named container, remove it: 
docker container rm kafka-connect-datagen

docker run -it --expose 8083 -p 8083:8083 \
  --env=host \
  --name=kafka-connect-datagen \
  -e CONNECT_BOOTSTRAP_SERVERS="$CONTAINER_BROKERS" \
  -e CONNECT_REST_HOST_NAME="0.0.0.0" \
  -e CONNECT_REST_PORT="8083" \
  -e CONNECT_REST_ADVERTISED_HOST_NAME="localhost" \
  -e CONNECT_REST_ADVERTISED_LISTENER="http" \
  -e CONNECT_REST_ADVERTISED_PORT="8083" \
  -e CONNECT_GROUP_ID="quickstart" \
  -e CONNECT_CONFIG_STORAGE_TOPIC="quickstart-config" \
  -e CONNECT_OFFSET_STORAGE_TOPIC="quickstart-offsets" \
  -e CONNECT_STATUS_STORAGE_TOPIC="quickstart-status" \
  -e CONNECT_KEY_CONVERTER="org.apache.kafka.connect.storage.StringConverter" \
  -e CONNECT_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
  -e CONNECT_INTERNAL_KEY_CONVERTER="org.apache.kafka.connect.storage.StringConverter" \
  -e CONNECT_INTERNAL_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
  -e CONNECT_QUICKSTART="Stock_Trades" \
  -e CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components" \
  cnfldemos/kafka-connect-datagen:0.1.7-5.3.1