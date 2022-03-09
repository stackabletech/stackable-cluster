#!/bin/bash

set -x

REPO_DIR=$(dirname $0)
NAMESPACE=${1}

echo ${REPO_DIR}

export SPARK_MASTER_POD=$(kubectl -n ${NAMESPACE} get pods -o=name | grep spark-master | sed "s/^.\{4\}//")
echo $SPARK_MASTER_POD

export SPARK_SLAVE_POD=$(kubectl -n ${NAMESPACE} get pods -o=name | grep spark-slave | sed "s/^.\{4\}//")
echo $SPARK_SLAVE_POD

#.jar needs to be distributed to pods
JAR_FILE="${REPO_DIR}/minimalSpark/distribution/minimalSpark.jar"

kubectl -n ${NAMESPACE} cp ${JAR_FILE} $SPARK_MASTER_POD:/tmp
kubectl -n ${NAMESPACE} cp ${JAR_FILE} $SPARK_SLAVE_POD:/tmp

#copy start script to master
SUBMIT_SCRIPT="${REPO_DIR}/scripts/spark-submit.sh"
kubectl -n ${NAMESPACE} cp ${SUBMIT_SCRIPT} $SPARK_MASTER_POD:/tmp

#copy resource file to master
RESOURCE_FILE="${REPO_DIR}/minimalSpark/src/main/resources/minimalSpark.txt"
kubectl -n ${NAMESPACE} cp ${RESOURCE_FILE} $SPARK_MASTER_POD:/tmp
kubectl -n ${NAMESPACE} cp ${RESOURCE_FILE} $SPARK_SLAVE_POD:/tmp

#make submit executable
kubectl exec -n ${NAMESPACE} --stdin $SPARK_MASTER_POD -- /bin/bash -c "chmod 700 /tmp/spark-submit.sh"
kubectl exec -n ${NAMESPACE} $SPARK_MASTER_POD -- /bin/bash -x -v -c "/tmp/spark-submit.sh ${NAMESPACE}" &> spark-log.txt