#!/bin/bash

#-------------------------------------------------------------------------------
# Load Configuration
#-------------------------------------------------------------------------------

echo Loading config...
. config/global-config.sh

#-------------------------------------------------------------------------------
# Only edit if you want to customize things:
#-------------------------------------------------------------------------------

# Install jq, needed for parsing responses from AWS CLI to extract broker info...
echo "Installing jq..."
sudo yum install jq -y

# Get MSK cluster ARN from CloudFormation stack outputs:
CLUSTER_ARN=$(aws cloudformation describe-stacks --stack-name $CLOUDFORMATION_STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='MskClusterArn'].OutputValue" --output text)
AWS_REGION=$(aws cloudformation describe-stacks --stack-name $CLOUDFORMATION_STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='StackRegion'].OutputValue" --output text)
S3_BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name $CLOUDFORMATION_STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" --output text)

echo "Installing Java 1.8 (needed for the version of Kafka that we use)..."
sudo yum install java-1.8.0 java-1.8.0-openjdk-devel -y
sudo yum remove java-1.7.0-openjdk -y

# Download the Apache Kafka project, which contains a helper script we will
# use to create a topic to send our dummy data to later: 
CURRENT_DIR=$(pwd)
KAFKA_DIR=kafka_2.12-2.2.1
if [ ! -d $KAFKA_DIR ]; then
  echo Downloading Kafka...
  wget https://archive.apache.org/dist/kafka/2.2.1/kafka_2.12-2.2.1.tgz
  tar -xzf kafka_2.12-2.2.1.tgz
else
  echo Kafka already downloaded...
fi

echo Getting ZooKeeper addresses...
ZOOKEEPER_STRING=$(aws kafka describe-cluster --cluster-arn $CLUSTER_ARN | jq ' .ClusterInfo.ZookeeperConnectString ' --raw-output)

# Create a topic for our dummy stock trade data:
REPLICATION_FACTOR=2
echo Creating topic "stock-trades" for our dummy data...
$KAFKA_DIR/bin/kafka-topics.sh --create \
  --zookeeper "$ZOOKEEPER_STRING" \
  --replication-factor $REPLICATION_FACTOR \
  --partitions 1 \
  --topic stock-trades

# Configure appropriate settings based on whether you want to use SSL:
if [ $USE_SSL -eq 1 ]
then
  echo Based on global config, TLS brokers will be used...
  BROKERS=$(aws kafka get-bootstrap-brokers --cluster-arn $CLUSTER_ARN | jq ' .BootstrapBrokerStringTls' --raw-output)
  SECURITY_PROTOCOL=SSL
else
  echo Based on global config, plaintext brokers will be used...
  BROKERS=$(aws kafka get-bootstrap-brokers --cluster-arn $CLUSTER_ARN | jq ' .BootstrapBrokerString' --raw-output)
  SECURITY_PROTOCOL=PLAINTEXT
fi

# Generate a test script that can read directly from our MSK topic to make sure
# that our Kafka Connect Source Connector is publishing data:
echo "Generating kafka-console-consumer.sh which you can later use to read data directly from our test topic in MSK..."
cat <<EOT > ./kafka-console-consumer.sh
$KAFKA_DIR/bin/kafka-console-consumer.sh \
  --bootstrap-server $BROKERS \
  --topic stock-trades --from-beginning
EOT
chmod 777 $CURRENT_DIR/kafka-console-consumer.sh


# Run our Kafka Connect demo container. Note - it takes a minute or two to finish setting up. 
# Once its done, it listens on a local port and we need to curl a command to the listener to
# tell it to start producing our demo data:
DIR=$(pwd)
PORT=$KAFKA_CONNECT_SOURCE_PORT
TOPIC_PREFIX=$KAFKA_CONNECT_SOURCE_TOPIC_PREFIX
echo Starting Kafka Connect source connector...
docker run -it --rm \
  -p $PORT:$PORT \
  --expose $PORT \
  --env=host \
  -e CONNECT_BOOTSTRAP_SERVERS="$BROKERS" \
  -e CONNECT_REST_HOST_NAME="0.0.0.0" \
  -e CONNECT_REST_PORT="$PORT" \
  -e CONNECT_REST_ADVERTISED_HOST_NAME="localhost" \
  -e CONNECT_REST_ADVERTISED_LISTENER="http" \
  -e CONNECT_REST_ADVERTISED_PORT="$PORT" \
  -e CONNECT_GROUP_ID="$TOPIC_PREFIX-group" \
  -e CONNECT_CONFIG_STORAGE_TOPIC="$TOPIC_PREFIX-config" \
  -e CONNECT_OFFSET_STORAGE_TOPIC="$TOPIC_PREFIX-offsets" \
  -e CONNECT_STATUS_STORAGE_TOPIC="$TOPIC_PREFIX-status" \
  -e CONNECT_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
  -e CONNECT_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
  -e CONNECT_KEY_CONVERTER_SCHEMAS_ENABLE="false" \
  -e CONNECT_VALUE_CONVERTER_SCHEMAS_ENABLE="false" \
  -e CONNECT_INTERNAL_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
  -e CONNECT_INTERNAL_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
  -e CONNECT_QUICKSTART="Stock_Trades" \
  -e CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components" \
  cnfldemos/kafka-connect-datagen:0.1.7-5.3.1