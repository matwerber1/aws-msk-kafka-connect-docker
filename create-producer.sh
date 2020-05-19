#!/bin/bash

#-------------------------------------------------------------------------------
# Load Configuration
#-------------------------------------------------------------------------------

echo Loading config...
. config/global.sh

#-------------------------------------------------------------------------------
# Only edit if you want to customize things:
#-------------------------------------------------------------------------------

# Get Cluster Info
echo Getting Amazon MSK broker and ZooKeeper addresses...
ZOOKEEPER_STRING=$(aws kafka describe-cluster --cluster-arn $CLUSTER_ARN | jq ' .ClusterInfo.ZookeeperConnectString ' --raw-output)
TLS_BROKERS=$(aws kafka get-bootstrap-brokers --region $CLUSTER_REGION --cluster-arn $CLUSTER_ARN | jq ' .BootstrapBrokerStringTls' --raw-output)
PLAINTEXT_BROKERS=$(aws kafka get-bootstrap-brokers --region $CLUSTER_REGION --cluster-arn $CLUSTER_ARN | jq ' .BootstrapBrokerString' --raw-output)

# Download the Apache Kafka project, which contains a helper script we will
# use to create a topic to send our dummy data to later: 
CURRENT_DIR=$(pwd)
KAFKA_DIR=kafka_2.12-2.2.1
if [ ! -d $KAFKA_DIR ]; then
  echo Downloading Kafka...
  get https://archive.apache.org/dist/kafka/2.2.1/kafka_2.12-2.2.1.tgz
  tar -xzf kafka_2.12-2.2.1.tgz
else
  echo Kafka already downloaded...
fi

# Create a topic for our dummy stock trade data:
REPLICATION_FACTOR=2
echo Creating topic "stock-trades" for our dummy data...
$KAFKA_DIR/bin/kafka-topics.sh --create \
  --zookeeper "$ZOOKEEPER_STRING" \
  --replication-factor $REPLICATION_FACTOR \
  --partitions 1 \
  --topic stock-trades

# Generate a 'consumer.sh' script we can later run to view data as it
# is being produced in the terminal (allows us to make sure producer is working):
echo "Generating run-consumer.sh which you can later use to read data from our test topic..."
cat <<EOT > ./run-consumer.sh
$KAFKA_DIR/bin/kafka-console-consumer.sh \
  --bootstrap-server $BROKERS \
  --topic stock-trades --from-beginning
EOT
chmod 777 $CURRENT_DIR/run-consumer.sh

# Configure appropriate settings based on whether you want to use SSL:
if [ $USE_SSL -eq 1 ]
then
  echo Based on global config, TLS brokers will be used...
  BROKERS=$TLS_BROKERS
  SECURITY_PROTOCOL=SSL
else
  echo Based on global config, plaintext brokers will be used...
  BROKERS=$PLAINTEXT_BROKERS
  SECURITY_PROTOCOL=PLAINTEXT
fi

# Run our Kafka Connect demo container. Note - it takes a minute or two to finish setting up. 
# Once its done, it listens on a local port and we need to curl a command to the listener to
# tell it to start producing our demo data:
DIR=$(pwd)
echo Starting Kafka Connect S3 Sync worker...
docker run -it --rm \
  -p $PRODUCER_PORT:$PRODUCER_PORT \
  --expose $PRODUCER_PORT \
  --env=host \
  -e CONNECT_BOOTSTRAP_SERVERS="$BROKERS" \
  -e CONNECT_REST_HOST_NAME="0.0.0.0" \
  -e CONNECT_REST_PORT="$PRODUCER_PORT" \
  -e CONNECT_REST_ADVERTISED_HOST_NAME="localhost" \
  -e CONNECT_REST_ADVERTISED_LISTENER="http" \
  -e CONNECT_REST_ADVERTISED_PORT="$PRODUCER_PORT" \
  -e CONNECT_GROUP_ID="$PRODUCER_TOPIC_PREFIX-group" \
  -e CONNECT_CONFIG_STORAGE_TOPIC="$PRODUCER_TOPIC_PREFIX-config" \
  -e CONNECT_OFFSET_STORAGE_TOPIC="$PRODUCER_TOPIC_PREFIX-offsets" \
  -e CONNECT_STATUS_STORAGE_TOPIC="$PRODUCER_TOPIC_PREFIX-status" \
  -e CONNECT_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
  -e CONNECT_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
  -e CONNECT_KEY_CONVERTER_SCHEMAS_ENABLE="false" \
  -e CONNECT_VALUE_CONVERTER_SCHEMAS_ENABLE="false" \
  -e CONNECT_INTERNAL_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
  -e CONNECT_INTERNAL_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
  -e CONNECT_QUICKSTART="Stock_Trades" \
  -e CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components" \
  cnfldemos/kafka-connect-datagen:0.1.7-5.3.1