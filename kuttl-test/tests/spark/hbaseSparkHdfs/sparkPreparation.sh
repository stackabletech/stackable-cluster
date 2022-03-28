#!/bin/bash

set -x

PROJECT_DIR=$(dirname $0)
NAMESPACE=${1}

echo ${PROJECT_DIR}

export SPARK_MASTER_POD=$(kubectl -n ${NAMESPACE} get pods -o=name | grep spark-master | sed "s/^.\{4\}//")
echo $SPARK_MASTER_POD

export SPARK_SLAVE_POD=$(kubectl -n ${NAMESPACE} get pods -o=name | grep spark-slave | sed "s/^.\{4\}//")
echo $SPARK_SLAVE_POD

export HBASE_POD=$(kubectl -n ${NAMESPACE} get pods -o=name | grep hbase-regionserver | sed "s/^.\{4\}//")
echo $HBASE_POD


#.jar needs to be distributed to pods
JAR_FILE="${PROJECT_DIR}/distribution/toBeDefined.jar"

kubectl -n ${NAMESPACE} cp ${JAR_FILE} $SPARK_MASTER_POD:/tmp
kubectl -n ${NAMESPACE} cp ${JAR_FILE} $SPARK_SLAVE_POD:/tmp

#copy start script to master
SUBMIT_SCRIPT="${PROJECT_DIR}/scripts/sparkHdfs-submit.sh"
kubectl -n ${NAMESPACE} cp ${SUBMIT_SCRIPT} $SPARK_MASTER_POD:/tmp

#make submit executable
kubectl exec -n ${NAMESPACE} --stdin $SPARK_MASTER_POD -- /bin/bash -c "chmod 700 /tmp/hbaseSpark-submit.sh"

#temp command until https://github.com/stackabletech/hdfs-operator/pull/148 is deployed
kubectl exec -n ${NAMESPACE} hdfs-namenode-default-0 -- /bin/bash -x -v -c "unset HADOOP_OPTS"

# copy hbase-site.xml to spark master
kubectl -n ${NAMESPACE} exec ${HBASE_POD} -- cat /stackable/hbase-2.4.9/conf/hbase-site.xml | kubectl -n ${NAMESPACE} exec -i ${SPARK_MASTER_POD} -- tee /stackable/spark/conf/hbase-site.xml

# copy jars to hbase see https://github.com/apache/hbase-connectors/tree/master/spark
kubectl -n ${NAMESPACE} cp "${PROJECT_DIR}/src/main/resources/hbase-spark-protocol-shaded-1.0.1-SNAPSHOT.jar" ${HBASE_POD}:/stackable/hbase-2.4.9/conf/
kubectl -n ${NAMESPACE} cp "${PROJECT_DIR}/src/main/resources/hbase-spark-1.0.1-SNAPSHOT.jar" ${HBASE_POD}:/stackable/hbase-2.4.9/conf/
cd "${PROJECT_DIR}/src/main/resources/" && wget https://repo1.maven.org/maven2/org/scala-lang/scala-library/2.12.14/scala-library-2.12.14.jar
kubectl -n ${NAMESPACE} cp "${PROJECT_DIR}/src/main/resources/scala-library-2.12.14.jar" ${HBASE_POD}:/stackable/hbase-2.4.9/conf/

#start spark job
kubectl exec -n ${NAMESPACE} $SPARK_MASTER_POD -- /bin/bash -x -v -c "/tmp/sparkHdfs-submit.sh" &> spark-log.txt


