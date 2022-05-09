#!/bin/bash

set -x

./create_test_cluster.py --debug --kind --operator zookeeper spark hbase hdfs

docker run --rm -v $(pwd)/test-jobs-root:/test-jobs-root \
          -w /test-jobs-root maven:3.8.5-jdk-8 mvn clean install