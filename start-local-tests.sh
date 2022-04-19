#!/bin/bash

set -x

docker run -u $(id -u ${USER}):$(id -g ${USER}) \
          --rm -v $(pwd)/test-jobs-root:/test-jobs-root \
          -w /test-jobs-root maven:3.8.4-jdk-8 mvn clean install

./create_test_cluster.py --debug --kind --operator spark hbase zookeeper hdfs

kubectl kuttl test -v 3