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
    export NAME_NODE_POD=hdfs-namenode-default-0

    kubectl exec -n $NAMESPACE $NAME_NODE_POD -- /bin/bash -c "unset HADOOP_OPTS && bin/hdfs dfs -test -e $1"

    # Validate results
    if [ $? -eq 0 ]; then
      #echo "$SPARK_FILE exists."
        logger::info "Found $EXPECTED_RESULT in $NAME_NODE_POD"
    else
       #Print failure message
        logger::fail  "$EXPECTED_RESULT does not exist on $NAME_NODE_POD."
    fi
}