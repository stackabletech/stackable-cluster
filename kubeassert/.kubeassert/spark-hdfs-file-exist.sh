#!/bin/bash

##
# @Name: spark-hdfs-file-exist
# @Description: Assert specified file has been written by spark job
# @Usage: kubectl assert spark-hdfs-file-exist
##

function spark-hdfs-file-exist {
    # Validate input arguments
    [[ -z $1 ]] && logger::error "You must specify a fully qualified file name '<file-name>.<type>'" && exit 1

    logger::assert "File with name $1 should be on path."

    kubectl exec -n $NAMESPACE hdfs-namenode-default-0 -- bin/hdfs dfs -test -e /tmp/$1

    # Validate results
    if [ $? -eq 0 ]; then
        logger::info "The return code equals to $?. Therefore, found $1 in $NAME_NODE_POD"
    else
        logger::fail  "The return code equals to $?. Therefore, $1 does not exist on $NAME_NODE_POD."
    fi
}