# aws-msk-kafka-connect-docker

This repository is a work in process and is tracking some of my early learning and tests of [Amazon Managed Streaming for Kafka](https://aws.amazon.com/msk/) (Amazon MSK), and [Confluent's Kafka Connect](https://docs.confluent.io/current/connect/index.html) to produce or consume data from the cluster. 

# Status

Not yet ready for prime time...

The data generator container is producing data in a format that is not compatible with the S3 Sync Connector (which must be Avro). Either that, or I have some mistakes with the key/value converters or other config parameters. Not sure, still learning. 

# Note

As you test this, if you change the converters (or certain other config), you will need to delete any previously-created topics for the corresponding connector or sync, since they will have been written using the old settings and you'll get an error trying to use them with the new settings. 

# Pre-requisites

1. Amazon MSK cluster running in your VPC with three nodes
2. AWS CLI configure with credentials file at `~/.aws/credentials` (we will mount this file to our Docker containers so they can send objects to S3s)

# Deployment

1. Edit `config/global.sh` to specify your MSK cluster, S3 bucket, etc.

2. Run `./create-producer.sh` to start a local Kakfa Connect demo container to send data to your cluster. Once the container is running, it needs to complete a few tasks before it is ready. 

    When you see a message like below, it should be ready: 
    
    ```
    [2020-05-15 21:13:33,884] INFO [Worker clientId=connect-1, groupId=stock-trades-group] Finished starting connectors and tasks (org.apache.kafka.connect.runtime.distributed.DistributedHerder)
    ```

    At this point, the container will listen on a local port and we need to issue a command to that port to start data generation in the next step.

3. Run `./invoke_producer.sh` to issue a local curl command to your running producer container and tell it to start sending data to your MSK cluster. 

4. Run `./consumer.sh` to start reading from the topic in step 3. After a moment, you should see data streaming to your screen. If this step is successful, you can stop the producer container and this task (as we just need a bit of data in your cluster to test the sync to S3).

5. Run `./create-s3-sync.sh` to create another Kafka Connect container, this time designed to sync data from MSK to your S3 bucket. 

6. Run `./invoke-s3-sync.sh` to trigger the container from Step 5 to start the sync process. 