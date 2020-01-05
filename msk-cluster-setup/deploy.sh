
  #!/bin/bash

# EDIT THESE VALUES
BUCKET=<YOUR_DEPLOYMENT_BUCKET>
MSK_SUBNETS=<YOUR_SUBNETS>
MSK_SECURITY_GROUPS=<YOUR_SECURITY_GROUPS>
NUMBER_OF_BROKER_NODES=2

# DO NOT EDIT BELOW (unless you want to)
STACK_NAME=aws-msk-learning


# Install Lambda function dependencies
sam build

if [ $? -ne 0 ]; then
    echo "SAM build failed"
fi

sam package \
    --s3-bucket $BUCKET \
    --template-file .aws-sam/build/template.yaml \
    --output-template-file packaged.yaml

if [ $? -ne 0 ]; then
    echo "SAM package failed"
fi

sam deploy \
    --template-file packaged.yaml \
    --stack-name $STACK_NAME \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides MskSubnets=$MSK_SUBNETS MskSecurityGroups=$MSK_SECURITY_GROUPS MskNumberOfBrokerNodes=$NUMBER_OF_BROKER_NODES
    
if [ $? -ne 0 ]; then
    echo "SAM deployment failed"
fi