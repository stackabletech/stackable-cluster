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

    export HBASE_INTERACTIVE_POD=$(kubectl -n ${NAMESPACE} get pods -o=name | grep hbase-interactive | sed "s/^.\{4\}//")
    logger::info "HBASE_INTERACTIVE_POD: $HBASE_INTERACTIVE_POD"

    logger::assert "Table should contain $2 rows."
    kubectl -n ${NAMESPACE} exec -t ${HBASE_INTERACTIVE_POD} -- /bin/bash -c "echo \"count 'stackable'\" | /stackable/hbase/bin/hbase shell -n"

    # Validate results
    if [ $? -eq 0 ]; then
        logger::info "The return code equals to $?. Therefore, found $1 in HBASE"
    else
        logger::fail  "The return code equals to $?. Therefore, $1 does not exist in HBASE."
    fi
}