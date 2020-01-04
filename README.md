# aws-msk-kafka-connect-docker

This repository is tracking some of my early learning and tests of Amazon Managed Streaming for Kafka (Amazon MSK), and Confluent's Kafka Connect to produce or consume data from the cluster. 

My vision, if time permits, is to have an easy-to-deploy project that creates: 

1. An Amazon MSK cluster
2. A fleet of Kafka Connect Docker containers to publish artificial load to the MSK cluster
3. A fleet of Kafka Connect Docker containers to consume and write the artificial data to Amazon S3

## Contents

`./msk-cluster` - contains AWS SAM template to deploy a new MSK cluster. You must configure the `deploy.sh` script to specify the subnet and security group configuration of your cluster. Optionally, review the `template.yml` for any other changes you may want to make, such as enforcing TLS encryption.

