# aws-msk-kafka-connect-docker

This repository is a work in process and is tracking some of my early learning and tests of [Amazon Managed Streaming for Kafka](https://aws.amazon.com/msk/) (Amazon MSK), and [Confluent's Kafka Connect](https://docs.confluent.io/current/connect/index.html) to produce or consume data from the cluster. 

My vision, if time permits, is to have an easy-to-deploy project that creates: 

1. An Amazon MSK cluster

2. A fleet of Kafka Connect containers on [AWS Fargate](https://aws.amazon.com/fargate/) to publish artificial load to the MSK cluster using the [Kafka Connect Datagen connector](https://github.com/confluentinc/kafka-connect-datagen). 

3. A fleet of Kafka Connect containers on AWS Fargate that use [Amazon S3 Sink Connector for the Confluent Platform](https://docs.confluent.io/current/connect/kafka-connect-s3/index.html) to read from the stream and write the data to Amazon S3.

I recently disccovered the awesome, serverless AWS Lambda-powered load testing offered by [Nordstrom's open source Serverless Artillery project](https://github.com/Nordstrom/serverless-artillery), so I might consider using this instead of #2, above... or maybe adding both options? 


## Contents

`./msk-cluster` - contains AWS SAM template to deploy a new MSK cluster. You must configure the `deploy.sh` script to specify the subnet and security group configuration of your cluster. Optionally, review the `template.yml` for any other changes you may want to make, such as enforcing TLS encryption.

`./kafka-connect` - contains the resources to build Confluent Kafka Connect stream publishers and consumers.