#!/bin/bash

# Load our configuration:
. config/global-config.sh

# Launch the stack:
aws cloudformation deploy \
  --template-file cloudformation.yaml \
  --stack-name $CLOUDFORMATION_STACK_NAME