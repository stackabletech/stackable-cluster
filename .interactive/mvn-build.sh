#!/bin/bash

set -x

# The base directory in which this repo was checked out
# As it may contain whitespaces, we take all params
BASE_DIR=${@}

docker run --rm -v "$BASE_DIR"/test-jobs-root:/test-jobs-root \
           -w /test-jobs-root maven:3.8.5-jdk-8 mvn clean install
exit