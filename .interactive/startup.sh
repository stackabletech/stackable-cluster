#!/bin/bash

set -x

export HOST_WORKSPACE=$(pwd)
export DOCKER_UID_GID="$(id -u):$(id -g)"
export GIT_LOCAL_BRANCH="hbase-test"
#export REPO_DIR='/stackable-cluster'

docker pull docker.stackable.tech/t2-testdriver

# execute maven build
docker run --rm -v "$HOST_WORKSPACE/../test-jobs-root":/test-jobs-root \
           -w /test-jobs-root maven:3.8.5-jdk-8 mvn clean install

# If you want to use the docker worm whole pattern (see https://ro14nd.de/Docker-Wormhole-Pattern) you can add the following volume
# --volume /var/run/docker.sock:/var/run/docker.sock \
docker run --rm \
    --volume "$HOST_WORKSPACE/target/:/target/" \
    --volume "$HOST_WORKSPACE/cluster.yaml:/cluster.yaml" \
    --volume "$HOST_WORKSPACE/test.sh:/test.sh" \
    --volume "$HOST_WORKSPACE/../:/stackable-cluster" \
    --env T2_TOKEN=$T2_TOKEN \
    --env T2_URL=https://t2.stackable.tech \
    --env UID_GID="$DOCKER_UID_GID" \
    --env DRY_RUN=false \
    --env SPARK_OPERATOR_VERSION=NIGHTLY \
    --env HDFS_OPERATOR_VERSION=NIGHTLY \
    --env ZOOKEEPER_OPERATOR_VERSION=NIGHTLY \
    --env HBASE_OPERATOR_VERSION=NIGHTLY \
    --env GIT_BRANCH=$GIT_LOCAL_BRANCH \
    --env INTERACTIVE_MODE=true \
    docker.stackable.tech/t2-testdriver

#--volume "$HOST_WORKSPACE/../test-jobs-root:/test-jobs-root" \