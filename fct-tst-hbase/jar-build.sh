#!/bin/bash

set -x

#docker run --rm -v $(pwd)/test-jobs-root:/test-jobs-root \
#          -w /test-jobs-root maven:3.8.5-jdk-8
ls -al

mvn -v

cd test-jobs-root && mvn clean install