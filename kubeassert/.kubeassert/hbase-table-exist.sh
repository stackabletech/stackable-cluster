#!/bin/bash

##
# @Name: hbase-table-exist
# @Description: Assert specified table has been has been created
# @Usage: kubectl assert hbase-table-exist
##

function hbase-table-exist {
    # Validate input arguments
    [[ -z $1 ]] && logger::error "You must specify a fully qualified table name '<file-name>'" && exit 1

    logger::assert "Table with name $1 should exist."

    kubectl exec -n default simple-hbase-master-default-0 -- bash -c "echo \"export HBASE_MANAGES_ZK=false\" > /stackable/conf/hbase-env.sh && echo \"exists 'stackable'\" | bin/hbase shell -n"
    status=$?

    # Validate results
    if [ $? -eq 0 ]; then
        logger::info "The results exist $?. Therefore, found $1 in $HBASE_NODE_POD"
    else
        logger::fail  "The results exist $?. Therefore, $1 does not exist on $HBASE_NODE_POD."
    fi
}