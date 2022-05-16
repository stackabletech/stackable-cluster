#!/bin/bash

set -x

PROJECT_DIR=$(dirname $0)
NAMESPACE=${1}

echo ${PROJECT_DIR}

export HBASE_INTERACTIVE_POD=$(kubectl -n ${NAMESPACE} get pods -o=name | grep hbase-interactive | sed "s/^.\{4\}//")
echo $HBASE_INTERACTIVE_POD

#.jar needs to be distributed to pod
JAR_FILE="${PROJECT_DIR}/hbase-1.0.jar"
kubectl -n ${NAMESPACE} cp ${JAR_FILE} $HBASE_INTERACTIVE_POD:/tmp

#start hbase job
kubectl exec -n ${NAMESPACE} $HBASE_INTERACTIVE_POD -- /bin/bash -x -v -c "java -jar /tmp/hbase-1.0.jar &>> /tmp/hbase-log.txt"


