# ./aws-msk-tutorial/

This directory contains resources to help you quickly test the production and consumption of messages by (mostly) automating [Step 5 - Create a Topic](https://docs.aws.amazon.com/msk/latest/developerguide/create-topic) and [Step 6 - Produce and Consume Data](https://docs.aws.amazon.com/msk/latest/developerguide/produce-consume).

# Prerequisites

1. An existing Amazon MSK cluster deployed using the SAM template within the [../msk-cluster-setup/](../msk-cluster-setup) section of this project.

2. A workstation that has connectivity to your Amazon MSK cluster. You will use this workstation to test publishing to and consuming from MSK topics.

  * Option 1 - Connectivity to your MSK cluster from your local machine (e.g. VPN access to your VPC or a public cluster). If you use this approach, you can run this guide from your local machine. 
  
  * Option 2 - Or, a cloud workstation such as an Amazon EC2, Cloud9, or Amazon Workspace instance in the same VPC as your MSK cluster, with security groups allowing communication between the two. If you use this approach, you should clone and run this project from your cloud workstation.

  If you don't already have one of the two options above, Amazon Cloud9 is the easiest way to set up a workstation in your VPC. Or, you could set up an EC2 instance following [Step 4 of the Amazon MSK Getting Started Guide](https://docs.aws.amazon.com/msk/latest/developerguide/create-client-machine.html). 


# Deployment

1. Run `./setup.sh` to gather information about your cluster and generate a `./producer.sh` and `./consumer.sh` script custom-tailored to your cluster.

2. In one terminal, start `./producer.sh`. You will see a prompt in which you can type messages. Each press of the `ENTER` key will send that line as a new message to the `AWSKafkaTutorialTopic` in your MSKcluster. 

3. In a separate terminal, start `./consumer.sh`. This will consume messages from your MSK cluster as they are received. 