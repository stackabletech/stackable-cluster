#!/bin/bash

set -x

SPARK_MASTER_IP=$(hostname -i | cut -d' ' -f2)

/stackable/spark/bin/spark-submit \
  --class com.stackable.operator.minimal \
  --master spark://${SPARK_MASTER_IP}:7078 \
  --deploy-mode client \
  --num-executors 2 \
  --executor-memory 1g \
  /tmp/minimalSpark.jar

exit 0