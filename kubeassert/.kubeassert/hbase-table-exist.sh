#!/bin/bash

##
# @Name: hbase-table-exist
# @Description: Assert specified table has been has been created
# @Usage: kubectl assert hbase-table-exist
##

function hbase-table-exist {
    NAMESPACE=${1}
    logger::info "NAMESPACE: $NAMESPACE"

    # Validate input arguments
    [[ -z $2 ]] && logger::error "You must specify a fully qualified table name '<file-name>'" && exit 1

    export HBASE_INTERACTIVE_POD=$(kubectl -n ${NAMESPACE} get pods -o=name | grep hbase-interactive | sed "s/^.\{4\}//")
    logger::info "HBASE_INTERACTIVE_POD: $HBASE_INTERACTIVE_POD"

    logger::assert "Table with name $2 should exist."
    kubectl -n ${NAMESPACE} exec -t ${HBASE_INTERACTIVE_POD} -- /bin/bash -c "echo \"describe 'stackable'\" | /stackable/hbase/bin/hbase shell -n"

    # Validate results
    if [ $? -eq 0 ]; then
        logger::info "The return code equals to $?. Therefore, found $1 in HBASE"
    else
        logger::fail  "The return code equals to $?. Therefore, $1 does not exist in HBASE."
    fi
}