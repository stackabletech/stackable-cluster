#!/bin/bash

##
# @Name: local-file-exist
# @Description: Assert specified file has been written by spark job
# @Usage: kubectl assert spark_file_exist
##

function local-file-exist {
    # Validate input arguments
    [[ -z $1 ]] && logger::error "You must specify a fully qualified file name '<file-name>.<type>'" && exit 1
    # Print assertion message
    logger::assert "File with name $1 should be on path."
    # Run some kubectl commands
    export SPARK_MASTER_POD=$(kubectl -n $NAMESPACE get pods -o=name | grep spark-master | sed "s/^.\{4\}//")
    echo $SPARK_MASTER_POD

    export SPARK_FILE=$(kubectl exec -n $NAMESPACE $SPARK_MASTER_POD -- ls /tmp/stacky | grep _SUCCESS | sed "s/^.\{0\}//" )
    echo $SPARK_FILE

    # Validate results
    if [ "${SPARK_FILE}" == $1 ]; then
        logger::info "Found $SPARK_FILE in $SPARK_MASTER_POD"
    else
        logger::fail  "$SPARK_FILE does not exist on $SPARK_MASTER_POD."
    fi
}