#!/bin/bash

##
# @Name: spark_file_exist
# @Description: Assert specified file has been written by spark job
# @Usage: kubectl assert spark_file_exist
##

function spark_file_exist {
    # Validate input arguments
    [[ -z $1 ]] && logger::error "You must specify a fully qualified file name '<file-name>.<type>'" && exit 1
    # Print assertion message
    logger::assert "File with name $1 should be on path."
    # Run some kubectl commands
    export SPARK_MASTER_POD=$(kubectl get pods -o=name | grep master | sed "s/^.\{4\}//")
    echo $SPARK_MASTER_POD

    #export $SPARK_FILE=$(kubectl exec --stdin --tty $SPARK_MASTER_POD -- /bin/bash -c "cd /tmp/ && -f \"$FILE_NAME\"")
    #export SPARK_FILE=$(kubectl exec $SPARK_MASTER_POD -- /bin/bash -x -c "[[ -d /tmp/StackyMcStackfaceSaysHello ]] && echo "StackyMcStackfaceSaysHello" || echo "File does not exist"")
    export SPARK_FILE=$(kubectl exec $SPARK_MASTER_POD -- ls /tmp/ | grep StackyMcStackfaceSaysHello | sed "s/^.\{0\}//" )
    echo $SPARK_FILE

    # Validate results
    if [ "${SPARK_FILE}" == $1 ]; then
      #echo "$SPARK_FILE exists."
        logger::info "Found $SPARK_FILE in $SPARK_MASTER_POD"
    else
       #Print failure message
        logger::fail  "$SPARK_FILE does not exist on $SPARK_MASTER_POD."
    fi
}