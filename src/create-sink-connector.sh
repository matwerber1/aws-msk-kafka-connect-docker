#!/bin/bash

#-------------------------------------------------------------------------------
# Load Configuration
#-------------------------------------------------------------------------------

echo Loading config...
. config/global-config.sh

#-------------------------------------------------------------------------------
# Only edit if you want to further customize:
#-------------------------------------------------------------------------------

# Install jq, needed for parsing responses from AWS CLI to extract broker info...
echo "Installing jq..."
sudo yum install jq -y

# Get MSK cluster ARN from CloudFormation stack outputs:
CLUSTER_ARN=$(aws cloudformation describe-stacks --stack-name $CLOUDFORMATION_STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='MskClusterArn'].OutputValue" --output text)
AWS_REGION=$(aws cloudformation describe-stacks --stack-name $CLOUDFORMATION_STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='StackRegion'].OutputValue" --output text)
S3_BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name $CLOUDFORMATION_STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" --output text)

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

# The file below will contain the config parameters that we later use to start our sink connector:
echo 'Creating config/sink-connector.config...'
cat <<EOT > config/sink-connector.config
{
  "name": "s3-sink-docker",
  "config": {
    "connector.class": "io.confluent.connect.s3.S3SinkConnector",
    "topics": "stock-trades",
    "s3.region": "$AWS_REGION",
    "s3.bucket.name": "$S3_BUCKET_NAME",
    "s3.part.size": 5242880,
    "flush.size": 10000, 
    "storage.class": "io.confluent.connect.s3.storage.S3Storage", 
    "format.class": "io.confluent.connect.s3.format.json.JsonFormat", 
    "schema.generator.class": "io.confluent.connect.storage.hive.schema.DefaultSchemaGenerator", 
    "partitioner.class": "io.confluent.connect.storage.partitioner.TimeBasedPartitioner",  
    "schema.compatibility": "NONE", "partition.duration.ms": 2000, 
    "path.format": "YYYY/M/d/h", 
    "locale": "US", 
    "timezone": "UTC", 
    "rotate.schedule.interval.ms": 60000
  }
}
EOT

# Run our Kafka Connect demo container. Note - it takes a minute or two to finish setting up. 
# Once its done, it listens on a local port and we need to curl a command to the listener to
# tell it to start producing our demo data:
DIR=$(pwd)
PORT=$KAFKA_CONNECT_SINK_PORT
TOPIC_PREFIX=$KAFKA_CONNECT_SINK_TOPIC_PREFIX
echo Starting Kafka Connect sink connector...
docker run -it --rm \
  -p $PORT:$PORT \
  --expose $PORT \
  --env=host \
  -e CONNECT_SECURITY_PROTOCOL=$SECURITY_PROTOCOL \
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
  -e HOME="/root" \
  -v ~/.aws/credentials:/root/.aws/credentials \
  $( (( USE_SSL == 1 )) && printf %s "-e CONNECT_SSL_TRUSTSTORE_LOCATION=/app/truststore.jks -v $DIR/ssl/client.truststore.jks:/app/truststore.jks") \
  confluentinc/cp-kafka-connect:5.4.2
