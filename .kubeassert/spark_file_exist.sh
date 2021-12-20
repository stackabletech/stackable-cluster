#!/bin/bash

##
# @Name: spark_file_exist
# @Description: Assert specified file has been written by spark job
# @Usage: kubectl assert spark_file_exist
##

function spark_file_exist {
    # Validate input arguments
    [[ -z $1 ]] && logger::error "You must specify a file name." && exit 1
    # Print assertion message
    logger::assert "File with name $1 should be on path."
    # Run some kubectl commands

    export $SPARK_FILE=$(kubectl exec --stdin --tty $SPARK_MASTER_POD -- /bin/bash -c "cd /tmp/ && -f \"$FILE_NAME\"")

    # Validate results
    if [ -f "$SPARK_FILE" == $1 ]; then
        echo "$SPARK_FILE exists."
        logger::info "Found $SPARK_FILE in $SPARK_MASTER_POD"
    else
      # Print failure message
        logger::fail  "$SPARK_FILE does not exist on $SPARK_MASTER_POD."
    fi
}