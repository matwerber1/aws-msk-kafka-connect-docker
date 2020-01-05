# ./msk-cluster/

This directory contains an AWS SAM template that creates a new Amazon MSK cluster. 

# Prerequisites

You must already have a VPC with at least two subnets in two different AZs (if us-east-1, cannot use us-east-1e), and a security group allowing inbound traffic from the resource(s) you later want to use to produce/consume messages. 

You can deploy this SAM template, or you can follow [Steps 1 through 3 in the Amazon MSK Getting Started Guide] (https://docs.aws.amazon.com/msk/latest/developerguide/getting-started.html).