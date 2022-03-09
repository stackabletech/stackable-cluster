#!/bin/bash

set -x

docker run --rm -v $(pwd)/kuttl-test/tests/spark:/spark/minimalSpark:rw -w /spark/minimalSpark gradle:7.3.3-jdk11 gradle clean build

./create_test_cluster.py --debug --kind --operator spark hbase zookeeper hdfs

kubectl kuttl test -v 3