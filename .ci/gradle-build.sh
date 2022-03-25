#!/bin/bash

set -x

# The base directory in which this repo was checked out
# As it may contain whitespaces, we take all params
BASE_DIR=${@}

docker run --rm -v "$BASE_DIR"/kuttl-test/tests/spark:/spark/minimalSpark:rw -w /spark/minimalSpark gradle:7.3.3-jdk11 gradle clean build
docker run --rm -v "$BASE_DIR"/kuttl-test/tests/spark:/spark/sparkHdfs:rw -w /spark/sparkHdfs gradle:7.3.3-jdk11 gradle clean build