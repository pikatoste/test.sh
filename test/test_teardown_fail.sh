#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "Failing teardown functions should not break the test"
run_test_script "$TEST_SCRIPT_DIR"/do_test_teardown_fail.sh
