# aws-msk-kafka-connect-docker

This project demonstrates how to use [Apache Kafka Connect](https://kafka.apache.org/documentation/#connect) to send data to a topic on an [Amazon MSK](https://aws.amazon.com/msk/) cluster and also shows how to use Kafka Connect to sync data from that same topic to an Amazon S3 bucket. 

A deep dive into Kafka and Kafka Connect is outside the scope of this project. Just know that Kafka Connect is a framework that lets you use **connectors** to either write data into Kafka or read data from Kafka and **sink** it to an external source. Since Amazon MSK is compatible with Kafka APIs, Kafka Connect will also work for Amazon MSK. 

We will use Confluent's [Kafka Connect Datagen](https://www.confluent.io/hub/confluentinc/kafka-connect-datagen/) to produce dummy stock data and write it to a `stock-trades` topic in MSK. Their Datagen project is a a Kafka Connect worker with custom plugins to generate dummy data. Note - In production, one would use Kafka Connect with pre-written connectors (or custom-written connectors) to read from real data sources such as relational databases, Amazon S3 buckets, DynamoDB streams, etc.

We will then use a separate Kafka Connect worker to read from our MSK cluster and write our stock data to Amazon S3. Rather than write our own S3 connector, we use Confluent's version ([confluentinc/cp-kafka-connect](https://hub.docker.com/r/confluentinc/cp-kafka-connect)) because it comes pre-packaged with their own [S3 Sink Connector](https://docs.confluent.io/current/connect/kafka-connect-s3/index.html) already written for us.

Both our data producer and S3 sink instances of Kafka Connect will run as Docker containers. 

# Architecture

This project deploys the following into your AWS account: 

1. Amazon VPC with three public and private subnets across three availability zones
2. Amazon Managed Streaming for Kafka (Amazon MSK) Cluster
3. Amazon S3 bucket
4. Amazon Cloud9 environment

# Deployment

1. Download [`cloudformation.yaml`](https://github.com/matwerber1/aws-msk-kafka-connect-docker/raw/master/src/cloudformation.yaml) from this github project, then [navigate to CloudFormation](https://us-west-2.console.aws.amazon.com/cloudformation/home?#/stacks/create/template), click **upload a template file**, upload the template, and click **Next**.

    1. Enter `msk-kafka-connect-demo` as the **stack name**

    2. Optionally, change the Class B CIDR if you do not want to use the default value.

    3. Click Next through the remaining screens, and finally click **Create Stack**. 

2. Wait about ~20 minutes for the stack to finish deploying.

3. Once deployed, Navigate to the [Amazon Cloud9 console](https://us-west-2.console.aws.amazon.com/cloud9/home?).

4. Within Cloud9, clone this project and move into the project's `src/` directory:

    ```
    git clone https://github.com/matwerber1/aws-msk-kafka-connect-docker.git

    cd aws-msk-kafka-connect-docker/src
    ```

5. Amazon Cloud9 instances have 8 GB EBS volumes by default. This is too small to accomodate the large Kafka container images and installation media we will download, so run `./resize-ebs.sh` to increase the size of the volume to 16 GB.

5. Run `./create-source-connector.sh` to start a local Kakfa Connect demo container to send data to your cluster. Once the container is running, it needs to complete a few tasks before it is ready. Leave this task running in its own terminal. When you see a message like below, it should be ready: 
    
    ```
    [2020-05-15 21:13:33,884] INFO [Worker clientId=connect-1, groupId=stock-trades-group] Finished starting connectors and tasks (org.apache.kafka.connect.runtime.distributed.DistributedHerder)
    ```

5. The step above create our Kafka Connect source connnector, but it is not producing data yet. When Kafka Connect starts, it listens on a local REST interface for commands, such as starting or stopping a task. To start our data generation, open a new Cloud9 terminal window and run `./start-source-connector.sh`, which will curl a simple API command to your container and tell it to start sending messages to the `stock-trades` topic in your MSK cluster. 

6. Run `./kafka-console-consumer.sh` to start reading messages we started sending to the `stock-trades` topic above. After a moment, you should see data streaming to your screen. If this step is successful, you can go ahead and stop the source connector and consumer terminal sessions from earlier, as we only need a little bit of data to test our sink connector in the next steps.

7. Run `./create-sink-connector.sh` to create another Kafka Connect container that contains the Confluent S3 sink connector. Leave this process running in the terminal.

8. In a new terminal, run `./start-sink-connector.sh` to trigger the sink connector container to read from the MSK `stock-trades` topic and write it to S3. 

9. After a minute or so, you should see activity in the sink connector's terminal that shows successful writes to S3; you can navigate to your S3 bucket to confirm. 