#!/bin/bash

set -x

/stackable/spark/bin/spark-submit \
  --class com.stackable.operator.minimal \
  --master spark://172.18.0.3:7078 \
  --deploy-mode client \
  --num-executors 1 \
  --executor-memory 1g \
  /tmp/minimalSpark.jar