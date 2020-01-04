# aws-msk-kafka-connect-docker

## Contents

`./msk-cluster` - contains AWS SAM template to deploy a new MSK cluster. You must configure the `deploy.sh` script to specify the subnet and security group configuration of your cluster. Optionally, review the `template.yml` for any other changes you may want to make, such as enforcing TLS encryption.

