#!/bin/bash

# These commands based on guide at: 
# https://docs.aws.amazon.com/msk/latest/developerguide/getting-started.html

CURRENT_DIR=$(pwd)
KAFKA_DIR=kafka_2.12-2.2.1

echo Downloading Kafka...
if [ ! -d $KAFKA_DIR ]; then
    wget https://archive.apache.org/dist/kafka/2.2.1/kafka_2.12-2.2.1.tgz
    tar -xzf kafka_2.12-2.2.1.tgz
else
  echo Kafka already downloaded...
fi

# This must match the CloudFormation stack name specified in the msk-cluster/deploy.sh script:
STACK_NAME="aws-msk-learning"

# Get MSK information:
echo Gathering MSK cluster info for CloudFormation stack $STACK_NAME...
CLUSTER_ARN=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='MskClusterArn'].OutputValue" --output text)
ZOOKEEPER_STRING=$(aws kafka describe-cluster --cluster-arn $CLUSTER_ARN | jq ' .ClusterInfo.ZookeeperConnectString ' --raw-output)
# Depending on how you've configured your MSK cluster, it might have TLS and/or plaintext broker endpoints: 
TLS_BROKERS=$(aws kafka get-bootstrap-brokers --region us-east-1 --cluster-arn $CLUSTER_ARN | jq ' .BootstrapBrokerStringTls' --raw-output)
PLAINTEXT_BROKERS=$(aws kafka get-bootstrap-brokers --region us-east-1 --cluster-arn $CLUSTER_ARN | jq ' .BootstrapBrokerString' --raw-output)

# This cannot be greater than the number of nodes in your MSK cluster:
REPLICATION_FACTOR=2

echo Creating test topic...
$KAFKA_DIR/bin/kafka-topics.sh --create \
  --zookeeper "$ZOOKEEPER_STRING" \
  --replication-factor $REPLICATION_FACTOR \
  --partitions 1 \
  --topic AWSKafkaTutorialTopic

# The section below based on: 
# https://www.baeldung.com/find-java-home
# and
# https://stackoverflow.com/questions/3466166/how-to-check-if-running-in-cygwin-mac-or-linux

echo 'Finding Java home (Mac and Linux supported, Windows will require manual edit to setup.sh)...'
if [ "$(uname)" == "Darwin" ]; then
  # Platform is Mac
  JAVA_HOME=$($(dirname $(readlink $(which javac)))/java_home)     
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  # Platform is Linux
  JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
  echo "Your platform is Windows x86. Edit setup.sh to set your appropriate JAVA_HOME and re-run..."
  JAVA_HOME="YOU NEED TO SET THIS"
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
  echo "Toue platform is Windows x64. Edit setup.sh to set your appropriate JAVA_HOME and re-run..."
  JAVA_HOME="YOU NEED TO SET THIS"
else
  echo "Unknown platform. Edit setup.sh to set your appropriate JAVA_HOME and re-run..."
  JAVA_HOME="YOU NEED TO SET THIS"
  exit
fi
echo JAVA_HOME=$JAVA_HOME

# We will copy our Java trust store to this directory to enable SSL communication with our MSK cluster: 
echo "Copying $JAVA_HOME/lib/security/cacerts to $CURRENT_DIR/ssl/kafka.client.truststore.jks..." 
mkdir -p ssl
cp $JAVA_HOME/lib/security/cacerts $CURRENT_DIR/ssl/kafka.client.truststore.jks

echo "Saving SSL config to .bin/client.properties..."
cat <<EOT > $KAFKA_DIR/bin/client.properties
security.protocol=SSL
ssl.truststore.location=$CURRENT_DIR/ssl/kafka.client.truststore.jks
EOT

echo "Generating producer.sh and consumer.sh scripts so you can use your cluster..."
cat <<EOT > $CURRENT_DIR/producer.sh
$KAFKA_DIR/bin/kafka-console-producer.sh \
  --broker-list $TLS_BROKERS \
  --producer.config $KAFKA_DIR/bin/client.properties \
  --topic AWSKafkaTutorialTopic
EOT

cat <<EOT > $CURRENT_DIR/consumer.sh
$KAFKA_DIR/bin/kafka-console-consumer.sh \
  --bootstrap-server $TLS_BROKERS \
  --consumer.config $KAFKA_DIR/bin/client.properties \
  --topic AWSKafkaTutorialTopic --from-beginning
EOT

chmod 777 $CURRENT_DIR/producer.sh
chmod 777 $CURRENT_DIR/consumer.sh

echo ""
echo "All done!"
echo ""
echo "You may now run ./producer.sh and ./consumer.sh from separate terminals."
echo "As you type messages in the producer window, watch as they appear in your consumer window :)"
echo ""