#!/bin/bash

set -x

/stackable/spark/bin/spark-submit \
  --class com.stackable.operator.minimal \
  --master spark://simple-master-default:7077 \
  --deploy-mode client \
  --num-executors 2 \
  --executor-memory 1g \
  /tmp/minimalSpark.jar
