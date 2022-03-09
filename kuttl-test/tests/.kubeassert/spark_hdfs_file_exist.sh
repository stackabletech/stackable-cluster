#!/bin/bash

##
# @Name: spark_file_exist
# @Description: Assert specified file has been written by spark job
# @Usage: kubectl assert spark_file_exist
##

function spark_file_exist {
    local EXPECTED_RESULT=${1}

    # Validate input arguments
    [[ -z ${EXPECTED_FILE_NAME} ]] && logger::error "You must specify a fully qualified file name '<file-name>.<type>'" && exit 1
    # Print assertion message
    logger::assert "File with name $1 should be on path."
    # Run some kubectl commands
    export NAME_NODE_POD=$(kubectl -n $NAMESPACE get pods -o=name | grep hdfs-namenode | sed "s/^.\{4\}//")
    echo $NAME_NODE_POD

    kubectl exec -n $NAMESPACE $NAME_NODE_POD -- bin/hdfs dfs -test -e ${EXPECTED_RESULT}
    #export SPARK_FILE=$(kubectl exec -n $NAMESPACE $NAME_NODE_POD -- bin/hdfs dfs -ls /tmp | grep ${EXPECTED_FILE_NAME} | sed "s/^.\{0\}//" )
    echo $1

    # Validate results
    if [ $? -eq 0 ]; then
      #echo "$SPARK_FILE exists."
        logger::info "Found $EXPECTED_RESULT in $NAME_NODE_POD"
    else
       #Print failure message
        logger::fail  "$EXPECTED_RESULT does not exist on $NAME_NODE_POD."
    fi
}