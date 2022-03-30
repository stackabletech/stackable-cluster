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
JAR_FILE="${PROJECT_DIR}/sparkHdfs/target/sparkHdfs-1.0.jar"

kubectl -n ${NAMESPACE} cp ${JAR_FILE} $SPARK_MASTER_POD:/tmp
kubectl -n ${NAMESPACE} cp ${JAR_FILE} $SPARK_SLAVE_POD:/tmp

#copy start script to master
SUBMIT_SCRIPT="${PROJECT_DIR}/sparkHdfs-submit.sh"
kubectl -n ${NAMESPACE} cp ${SUBMIT_SCRIPT} $SPARK_MASTER_POD:/tmp

#make submit executable
kubectl exec -n ${NAMESPACE} --stdin $SPARK_MASTER_POD -- /bin/bash -c "chmod 700 /tmp/sparkHdfs-submit.sh"

#temp command until https://github.com/stackabletech/hdfs-operator/pull/148 is deployed
#kubectl exec -n ${NAMESPACE} hdfs-namenode-default-0 -- /bin/bash -x -v -c "unset HADOOP_OPTS"

#start spark job
kubectl exec -n ${NAMESPACE} $SPARK_MASTER_POD -- /bin/bash -x -v -c "/tmp/sparkHdfs-submit.sh" &> spark-log.txt


