#!/bin/bash

set -x

PROJECT_DIR=$(dirname $0)
NAMESPACE=${1}

echo ${PROJECT_DIR}

export SPARK_MASTER_POD=$(kubectl -n ${NAMESPACE} get pods -o=name | grep spark-master | sed "s/^.\{4\}//")
echo $SPARK_MASTER_POD

export SPARK_SLAVE_POD=$(kubectl -n ${NAMESPACE} get pods -o=name | grep spark-slave | sed "s/^.\{4\}//")
echo $SPARK_SLAVE_POD

#.jar needs to be distributed to pods
JAR_FILE="${PROJECT_DIR}/spark-standalone-1.0.jar"
echo $JAR_FILE

kubectl -n ${NAMESPACE} cp ${JAR_FILE} $SPARK_MASTER_POD:/tmp
kubectl -n ${NAMESPACE} cp ${JAR_FILE} $SPARK_SLAVE_POD:/tmp

#copy start script to master
SUBMIT_SCRIPT="${PROJECT_DIR}/spark-submit.sh"
kubectl -n ${NAMESPACE} cp ${SUBMIT_SCRIPT} $SPARK_MASTER_POD:/tmp

#copy resource file to master
RESOURCE_FILE="${PROJECT_DIR}/minimalSpark.csv"
kubectl -n ${NAMESPACE} cp ${RESOURCE_FILE} $SPARK_MASTER_POD:/tmp
kubectl -n ${NAMESPACE} cp ${RESOURCE_FILE} $SPARK_SLAVE_POD:/tmp

#make submit executable
kubectl exec -n ${NAMESPACE} --stdin $SPARK_MASTER_POD -- /bin/bash -c "chmod 700 /tmp/spark-submit.sh"

#start spark job
kubectl exec -n ${NAMESPACE} $SPARK_MASTER_POD -- /bin/bash -x -v -c "/tmp/spark-submit.sh" &> spark-log.txt


