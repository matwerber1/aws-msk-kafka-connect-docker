# ./kafka-connect/kafka-connect-datagen/

This directory contains resources to deploy a Kafka Connect Container with the Datagen Connector and then invoke it to generate sample stock trade data.

# Deployment

1. Start the Kafka Connect container (and create a `consumer.sh` script you will run later):

  ```
  ./start-kafka-connect.sh
  ```

2. Invoke the Connect API to tell it to start generating stock-trade data:

  ```
  ./invoke-datagen-api.sh
  ```

3. In a separate terminal, run a consumer to view the data being generated: 

  ```
  ./consumer.sh
  ```