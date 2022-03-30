#!/bin/bash

set -x


/stackable/spark/bin/spark-submit \
  --class com.stackable.operator.minimal \
  --master spark://spark-master-default-0:7077 \
  --deploy-mode client \
  --num-executors 2 \
  --executor-memory 1g \
  --verbose \
  /tmp/sparkMinimal-1.0.jar