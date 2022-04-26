#!/bin/bash

set -x

PROJECT_DIR=$(dirname $0)
NAMESPACE=${1}

echo ${PROJECT_DIR}

export HABSE_MASTER_POD=$(kubectl -n ${NAMESPACE} get pods -o=name | grep hbase-master | sed "s/^.\{4\}//")
echo $HABSE_MASTER_POD

#.jar needs to be distributed to pods
JAR_FILE="${PROJECT_DIR}/target/hbase-1.0.jar"

kubectl -n ${NAMESPACE} cp ${JAR_FILE} $HABSE_MASTER_POD:/tmp

#copy start script to master
SUBMIT_SCRIPT="${PROJECT_DIR}/start-hbaseTest.sh"
kubectl -n ${NAMESPACE} cp ${SUBMIT_SCRIPT} $HABSE_MASTER_POD:/tmp

#make submit executable
kubectl exec -n ${NAMESPACE} --stdin $HABSE_MASTER_POD -- /bin/bash -c "chmod 700 /tmp/start-hbaseTest.sh"

#start hbase job
kubectl exec -n ${NAMESPACE} $HABSE_MASTER_POD -- /bin/bash -x -v -c "/tmp/start-hbaseTest.sh" &> spark-log.txt


