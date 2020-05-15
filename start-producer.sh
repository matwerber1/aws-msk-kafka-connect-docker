#!/bin/bash

#-------------------------------------------------------------------------------
# CONFIGURE THIS:
#-------------------------------------------------------------------------------
REGION="us-west-2"
CLUSTER_ARN="arn:aws:kafka:us-west-2:544941453660:cluster/my-cluster/327fed8e-e90d-439d-8477-d31fc2ce7117-3"
USE_TLS_BROKERS=1

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

# We download Kafka project, which contains some helper scripts we will later use: 
CURRENT_DIR=$(pwd)
KAFKA_DIR=kafka_2.12-2.2.1
echo Downloading Kafka...
if [ ! -d $KAFKA_DIR ]; then
    wget https://archive.apache.org/dist/kafka/2.2.1/kafka_2.12-2.2.1.tgz
    tar -xzf kafka_2.12-2.2.1.tgz
else
  echo Kafka already downloaded...
fi

# We create a topic that we will later publish to and consume messages from:
REPLICATION_FACTOR=2
echo Creating test topic...
$KAFKA_DIR/bin/kafka-topics.sh --create \
  --zookeeper "$ZOOKEEPER_STRING" \
  --replication-factor $REPLICATION_FACTOR \
  --partitions 1 \
  --topic stock-trades

# We generate a consumer.sh script below which will allow us to view messages
# coming in to the topic (once we later start producing them):
echo "Generating consumer.sh script that you can later use to view generated data..."
cat <<EOT > $CURRENT_DIR/consumer.sh
$KAFKA_DIR/bin/kafka-console-consumer.sh \
  --bootstrap-server $BROKERS \
  --topic stock-trades --from-beginning
EOT

chmod 777 $CURRENT_DIR/consumer.sh

# Run our Kafka Connect demo container. Note - it takes a minute or two to finish setting up. 
# Once its done, it listens on a local port and we need to curl a command to the listener to
# tell it to start producing our demo data:

if [ $USE_TLS_BROKERS -eq 1 ]
then
docker run -it --rm --expose 8083 -p 8083:8083 \
  --env=host \
  -e CONNECT_ENABLED_PROTOCOLS=TLSv1.2,TLSv1.1,TLSv1 \
  -e CONNECT_SECURITY_PROTOCOL=SSL \
  -e CONNECT_SSL_TRUSTSTORE_LOCATION=/usr/lib/jvm/zulu-8-amd64/jre/lib/security/cacerts \
  -e CONNECT_SSL_TRUSTSTORE_PASSWORD=changeit \
  -e CONNECT_BOOTSTRAP_SERVERS="$BROKERS" \
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
else
docker run -it --rm --expose 8083 -p 8083:8083 \
  --env=host \
  -e CONNECT_BOOTSTRAP_SERVERS="$BROKERS" \
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
fi