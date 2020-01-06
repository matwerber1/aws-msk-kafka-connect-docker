# aws-msk-kafka-connect-docker

This repository is a work in process and is tracking some of my early learning and tests of [Amazon Managed Streaming for Kafka](https://aws.amazon.com/msk/) (Amazon MSK), and [Confluent's Kafka Connect](https://docs.confluent.io/current/connect/index.html) to produce or consume data from the cluster. 

## Usage

The repo is a bit disorganized right now, containing several parallel and related tracks. 

The folder structure is: 

* [msk-cluster-setup](./msk-cluster-setup/) - contains AWS SAM template to deploy a new MSK cluster. You must configure the `deploy.sh` script to specify the subnet and security group configuration of your cluster. Optionally, review the `template.yml` for any other changes you may want to make, such as enforcing TLS encryption.

* [aws-msk-tutorial](./aws-msk-tutorial/) - contains scripts to automate the basic producer and consumer tests from the official [AWS MSK Getting Started Guide](https://docs.aws.amazon.com/msk/latest/developerguide/getting-started.html). These are simple tests where you type messages into a terminal that are then posted to a test topic in your cluster, and you can watch as they are received by a consumer script running in a separate terminal. 

* [kafka-connect](./kafka-connect) - contains the resources to build dockerized Confluent Kafka Connect stream publishers and consumers. The publisher uses Confluent's datagen connector to generate simulated streaming data, and the consumer uses Confluent's S3 Connector to consume and write messages to Amazon S3.