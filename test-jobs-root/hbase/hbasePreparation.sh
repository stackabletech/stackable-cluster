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
# pass variables to job:
# hbase-site-path: /stackable/conf/hbase/hbase-site.xml
# hdfs-site-path: /stackable/conf/hdfs/hdfs-site.xml
# core-site-path: /stackable/conf/hdfs/core-site.xml
kubectl exec -n ${NAMESPACE} $HBASE_INTERACTIVE_POD -- /bin/bash -x -v -c "java -jar /tmp/hbase-1.0.jar \
                                                                          --targetTable stackable \
                                                                          --input /tmp/testdata.txt \
                                                                          --hbaseSite /stackable/conf/hbase/hbase-site.xml \
                                                                          --hdfsSite  /stackable/conf/hdfs/hdfs-site.xml \
                                                                          --coreSite /stackable/conf/hdfs/core-site.xml \
                                                                          &>> /tmp/hbase-log.txt"


