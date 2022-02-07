#!/bin/bash

set -x

HOST_WORKSPACE=${1}

docker run --rm -v $HOST_WORKSPACE/kuttl-test/tests/spark:/spark/minimalSpark:rw -w /spark/minimalSpark gradle:7.3.3-jdk11 gradle clean build

exit_code=$?

exit $exit_code