#!/bin/bash
git clone -b "$GIT_BRANCH" https://github.com/stackabletech/stackable-cluster.git
(cd stackable-cluster/ && ./run_tests.sh)
exit_code=$?
exit $exit_code