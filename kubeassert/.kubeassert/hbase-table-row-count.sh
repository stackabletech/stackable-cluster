#!/bin/bash

##
# @Name: hbase-table-row-count
# @Description: Assert specified table has been has been created
# @Usage: kubectl assert hbase-table-row-count
##

function hbase-table-row-count {
    NAMESPACE=${1}
    logger::info "NAMESPACE: $NAMESPACE"

    # Validate input arguments
    [[ -z $2 ]] && logger::error "You must specify a count of expected rows" && exit 1

    logger::assert "Table should contain $2 rows."
    kubectl -n ${NAMESPACE} exec -t hbase-interactive -- /bin/bash -c "echo \"count 'w'\" | /stackable/hbase/bin/hbase shell --conf /stackable/conf/hbase/ -n"

    # Validate results
    # Improvement: Handle meaningful returns. Not just return code. see https://github.com/stackabletech/stackable-cluster/issues/53
    if [ $? -eq 0 ]; then
        logger::info "The return code equals to $?. Therefore, found $1 in HBASE"
    else
        logger::fail  "The return code equals to $?. Therefore, $1 does not exist in HBASE."
    fi
}