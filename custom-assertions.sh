#!/bin/bash

function sparkFileExists {
    # Validate input arguments
    [[ -z $1 ]] && logger::error "You must specify a file name." && exit 1
    # Print assertion message
    logger::assert "File with name $1 should be on path."
    # Run some kubectl commands
    kubectl config get-clusters
    # Validate results
    if cat $HOME/.kubeassert/result.txt | grep -q ^$1$; then
      # Print normal logs
      logger::info "Found $1 in kubeconfig."
    else
      # Print failure message
      logger::fail "$1 not found."
    fi
}