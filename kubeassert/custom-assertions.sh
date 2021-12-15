#!/bin/bash

function sparkFileExists {
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