# aws-msk-kafka-connect-docker

This project demonstrates how to use [Apache Kafka Connect](https://kafka.apache.org/documentation/#connect) to send data to a topic on an [Amazon MSK](https://aws.amazon.com/msk/) cluster and also shows how to use Kafka Connect to sync data from that same topic to an Amazon S3 bucket. 

A deep dive into Kafka and Kafka Connect is outside the scope of this project. Just know that Kafka Connect is a framework that lets you use **connectors** to either write data into Kafka or read data from Kafka and **sink** it to an external source. Since Amazon MSK is compatible with Kafka APIs, Kafka Connect will also work for Amazon MSK. 

We will use Confluent's [Kafka Connect Datagen](https://www.confluent.io/hub/confluentinc/kafka-connect-datagen/) to produce dummy stock data and write it to a `stock-trades` topic in MSK. Their Datagen project is a a Kafka Connect worker with custom plugins to generate dummy data. Note - In production, one would use Kafka Connect with pre-written connectors (or custom-written connectors) to read from real data sources such as relational databases, Amazon S3 buckets, DynamoDB streams, etc.

We will then use a separate Kafka Connect worker to read from our MSK cluster and write our stock data to Amazon S3. Rather than write our own S3 connector, we use Confluent's version ([confluentinc/cp-kafka-connect](https://hub.docker.com/r/confluentinc/cp-kafka-connect)) because it comes pre-packaged with their own [S3 Sink Connector](https://docs.confluent.io/current/connect/kafka-connect-s3/index.html) already written for us.

Both our data producer and S3 sink instances of Kafka Connect will run as Docker containers. 



## 3. AWS CLI / Credentials

We will create an instance of Kafka Connect that uses the [Confluent S3 sink connector](https://docs.confluent.io/current/connect/kafka-connect-s3/index.html) to read data from our test topic and write it to Amazon S3. Since we're runnning the S3 sink connenctor as a Docker container, we need to pass in AWS credentials to the container that allow it to write to Amazon S3. 

To do this, you should:

1. Create an IAM user that has an IAM policy granting access to write objects to the S3 bucket you created for this demo. 
2. Create AWS access keys for the user
3. Run `aws configure` from the machine that you're running this project on, and enter the user's access credentials

The steps above will store the access keys locally at `~/.aws/credentials`. When we later run our S3 sink Docker container, we will mount this file within the container so that Kafka Connect can access the credentials.

The IAM user for Kafka Connect needs a very basic set of IAM permissions to write to your Amazon S3 bucket: 

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "WriteToKafkaDemoBucket",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::YOUR_DEMO_BUCKET/*"
            ]
        }
    ]
}
```

## 4. Java 1.8 JDK

You will need Java/JDK version >=1.8 to run Kafka Connect. You can install the open source [Amazon Corretto Java 8](https://docs.aws.amazon.com/corretto/latest/corretto-8-ug/amazon-linux-install.html) or another distribution of your choice. 

## Connectivity to Private Resources in your VPC

You need to run your Kafka Connect Docker containers from a machine that has connectivity to your MSK cluster. If you follow recommendations in this guide, your MSK cluster would be in a private subnet, meaning you would either need to connect to your VPC (e.g. using VPN) if using an external/personal machine or you would directly run the demo project / containers from an EC2 instance running in your VPC.

For simplicity, I recommend launching a Cloud9 instance in your VPC. If you use the optional included CloudFormation template in this project, we will create a Cloud9 instance and MSK cluster for you with security groups that allow the two to communicate.

# Deployment

1. Clone this project:

    ```
    git clone https://github.com/matwerber1/aws-msk-kafka-connect-docker.git
    ```

2. OPTIONAL - if you don't already have an MSK cluster, you can deploy the included Cloudformation template, `cloudformation.yaml` to deploy an MSK cluster (and Cloud9 instance) in private subnets in a new VPC:

    ```
    aws cloudformation deploy --template-file cloudformation.yaml --stack-name msk-kafka-connect-demo
    ```
    

2. Edit `config/global.sh` to specify your MSK cluster ARN, S3 bucket name and region, and whether or not you will use SSL to communicate with your brokers:

    ```sh
    # config/global.sh
    S3_REGION=YOUR_S3_BUCKET_REGION
    S3_BUCKET_NAME=YOUR_S3_BUCKET_NAME
    CLUSTER_REGION=YOUR_MSK_CLUSTER_REGION
    CLUSTER_ARN=YOUR_MSK_CLUSTER_ARN
    USE_SSL=0
    ```

3. OPTIONAL - required if you chose to use SSL by settiing `USE_SSL=1`. If so, you will need to copy your `cacerts` from your local Java installation to the `./ssl/` project directory so that we can provide it to our Kafka Connect docker container at runtime. [Follow these instructions to do so](https://docs.aws.amazon.com/msk/latest/developerguide/msk-working-with-encryption.html). You should just need to run a simple copy command like the one below (your path may vary based on which Java version you have and where it is installed):

    ```sh
    cp /usr/lib/jvm/java-1.7.0-openjdk.x86_64/jre/lib/security/cacerts ./ssl/client.truststore.jks
    ```

    **NOTE** - I've already included my client.truststore.jks file in this GitHub project (from Amazon Correto Java 1.8, on an EC2 Cloud9 instance).I'm not sure whether you can use this file as-is or whether you truly need to copy your own like the command above. Try it and see what happens?

4. In a new terminal, run `./create-producer.sh` to start a local Kakfa Connect demo container to send data to your cluster. Once the container is running, it needs to complete a few tasks before it is ready. Leave this task running in its own terminal. When you see a message like below, it should be ready: 
    
    ```
    [2020-05-15 21:13:33,884] INFO [Worker clientId=connect-1, groupId=stock-trades-group] Finished starting connectors and tasks (org.apache.kafka.connect.runtime.distributed.DistributedHerder)
    ```

5. The step above starts our Kafka Connect data producer, but no data is being produced yet. When Kafka Connect starts, it listens on a local REST interface for commands, such as starting or stopping a task. To start our data generation, run `./invoke_producer.sh`, which will curl a simple API command to your container and tell it to start sending messages to the `stock-trades` topic in your MSK cluster. 

6. Run `./consumer.sh` to start reading messages we started sending to the `stock-trades` topic above. After a moment, you should see data streaming to your screen. If this step is successful, you can optionally stop the producer container and the consumer task, as we only need a little bit of data to test our S3 sync connector in the next steps.

7. Run `./create-s3-sync.sh` to create another Kafka Connect container that contains the Confluent S3 Sync connector and is configured to read messages from the `stock-trades` topic in MSK and write them to your S3 bucket. 

8. Again, Kafka Connect needs to be invoked via its REST API before it actually does anything. Run `./invoke-s3-sync.sh` to trigger the S3 Sync connector. 

9. After a minute or so, you should see activity in the S3 Sync Connector's terminal that shows successful writes to S3; you can navigate to your S3 bucket to confirm. 