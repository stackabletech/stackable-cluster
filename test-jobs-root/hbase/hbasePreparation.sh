#!/bin/bash

set -x

PROJECT_DIR=$(dirname $0)
NAMESPACE=${1}

echo ${PROJECT_DIR}

# set env with name of HBASE interactive pod. This pod is used to communicate with the HBASE
export HBASE_INTERACTIVE_POD=$(kubectl -n ${NAMESPACE} get pods -o=name | grep hbase-interactive | sed "s/^.\{4\}//")
echo $HBASE_INTERACTIVE_POD

# set env with name of HDFS Namenode. Needed to upload test data to HDFS
export HDFS_NAMENODE=$(kubectl -n ${NAMESPACE} get pods -o=name | grep hdfs-namenode-default-0 | sed "s/^.\{4\}//")
echo $HDFS_NAMENODE

# .jar needs to be distributed to pod
JAR_FILE="${PROJECT_DIR}/hbase-1.0.jar"
kubectl -n ${NAMESPACE} cp ${JAR_FILE} $HBASE_INTERACTIVE_POD:/tmp

# upload test data to hdfs
RESOURCE="${PROJECT_DIR}/wine-dataset-tiny.txt"
RESOURCE_FILE="wine-dataset-tiny.txt"
kubectl -n ${NAMESPACE} cp ${RESOURCE} $HDFS_NAMENODE:/tmp
kubectl exec -n ${NAMESPACE} $HDFS_NAMENODE -- /bin/bash -x -v -c "bin/hdfs dfs -put /tmp/${RESOURCE_FILE} /hbase"

# start hbase job
# pass variables to job:
# hbase-site-path: /stackable/conf/hbase/hbase-site.xml
# hdfs-site-path: /stackable/conf/hdfs/hdfs-site.xml
# core-site-path: /stackable/conf/hdfs/core-site.xml
kubectl exec -n ${NAMESPACE} $HBASE_INTERACTIVE_POD -- /bin/bash -x -v -c "java -jar /tmp/hbase-1.0.jar \
                                                                          --targetTable stackable \
                                                                          --input /hbase/wine-dataset-tiny.txt \
                                                                          --hbaseSite /stackable/conf/hbase/hbase-site.xml \
                                                                          --hdfsSite  /stackable/conf/hdfs/hdfs-site.xml \
                                                                          --coreSite /stackable/conf/hdfs/core-site.xml \
                                                                          &>> /tmp/hbase-log.txt"


