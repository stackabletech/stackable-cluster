#!/bin/bash

set -x

helm repo update

./create_test_cluster.py --debug --kind --operator zookeeper spark hbase hdfs secret commons

docker run --rm -v $(pwd)/test-jobs-root:/test-jobs-root \
          -w /test-jobs-root maven:3.8.5-jdk-8 mvn clean install