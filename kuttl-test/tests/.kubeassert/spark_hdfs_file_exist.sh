#!/bin/bash

##
# @Name: spark_hdfs_file_exist
# @Description: Assert specified file has been written by spark job
# @Usage: kubectl assert spark_hdfs_file_exist
##

function spark_hdfs_file_exist {
    # Validate input arguments
    [[ -z $1 ]] && logger::error "You must specify a fully qualified file name '<file-name>.<type>'" && exit 1
    # Print assertion message
    logger::assert "File with name $1 should be on path."

    # Run some kubectl commands
    # TODO: Find a better way then this to get the podname
    # export NAME_NODE_POD=$(kubectl -n ${NAMESPACE} get pods -o=name | grep hdfs-namenode-default-0 | sed "s/^.\{4\}//")
    export NAME_NODE_POD=hdfs-namenode-default-0

    kubectl exec -n $NAMESPACE $NAME_NODE_POD -- /bin/bash -c "bin/hdfs dfs -test -e /tmp/$1"

    # Validate results
    if [ $? -eq 0 ]; then
        logger::info "$1 exists on $NAME_NODE_POD"
    else
        logger::fail "$1 missing on $NAME_NODE_POD"
    fi
}