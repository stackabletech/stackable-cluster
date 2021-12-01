#!/bin/bash

set -x
#.jar needs to be distributed to pods
kubectl cp ~/Repo/stackable/stackable-cluster/spark/minimalSpark/build/libs/minimalSpark.jar spark-simple-slave-2core2g-stkblclstrcontrolplane-x4w5l:/tmp
kubectl cp ~/Repo/stackable/stackable-cluster/spark/minimalSpark/build/libs/minimalSpark.jar spark-simple-master-default-stkblclstrcontrolplane-h9ds7:/tmp

#copy start script to master
kubectl cp ~/Repo/stackable/stackable-cluster/scripts/spark-submit.sh spark-simple-master-default-stkblclstrcontrolplane-h9ds7:/tmp

#copy resource file to master
kubectl cp ~/Repo/stackable/stackable-cluster/spark/minimalSpark/src/main/resources/minimalSpark.txt spark-simple-master-default-stkblclstrcontrolplane-h9ds7:/tmp
kubectl cp ~/Repo/stackable/stackable-cluster/spark/minimalSpark/src/main/resources/minimalSpark.txt spark-simple-slave-2core2g-stkblclstrcontrolplane-x4w5l:/tmp