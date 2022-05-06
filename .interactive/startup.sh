#!/bin/bash

set -x

export HOST_WORKSPACE=$(pwd)
export DOCKER_UID_GID="$(id -u):$(id -g)"
export GIT_LOCAL_BRANCH="hbase-test"
#export REPO_DIR='/stackable-cluster'

docker pull docker.stackable.tech/t2-testdriver

# execute maven build
# sh ./mvn-build.sh $HOST_WORKSPACE/..
docker run --rm -v "$HOST_WORKSPACE/../test-jobs-root":/test-jobs-root \
           -w /test-jobs-root maven:3.8.5-jdk-8 mvn clean install

docker run --rm \
    --volume "$HOST_WORKSPACE/target/:/target/" \
    --volume "$HOST_WORKSPACE/cluster.yaml:/cluster.yaml" \
    --volume "$HOST_WORKSPACE/test.sh:/test.sh" \
    --volume "$HOST_WORKSPACE/../test-jobs-root:/test-jobs-root" \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --env T2_TOKEN=$T2_TOKEN \
    --env T2_URL=https://t2.stackable.tech \
    --env UID_GID="$DOCKER_UID_GID" \
    --env DRY_RUN=true \
    --env SPARK_OPERATOR_VERSION=NIGHTLY \
    --env GIT_BRANCH=$GIT_LOCAL_BRANCH \
    --env INTERACTIVE_MODE=true \
    docker.stackable.tech/t2-testdriver

