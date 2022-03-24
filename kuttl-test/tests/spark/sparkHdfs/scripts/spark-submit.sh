#!/bin/bash

set -x

NAMESPACE=${1}

/stackable/spark/bin/spark-submit \
  --class com.stackable.operator.minimal \
  --master spark://spark-master-default-0:7077 \
  --deploy-mode client \
  --conf spark.hadoop.fs.defaultFS="hdfs://hdfs-namenode-default-0:8020" \
  --num-executors 2 \
  --executor-memory 1g \
  --verbose \
  /tmp/sparkHdfs.jar