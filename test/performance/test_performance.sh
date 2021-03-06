#!/bin/bash
STACK_TRACE=full
source "$(dirname "$(readlink -f "$0")")"/../../test.sh

NUM_RUNS=${NUM_RUNS:-100}

start_test "Performance of inline test"
time for (( i=0; i<NUM_RUNS; i++)); do "$TEST_SCRIPT_DIR"/test_inline.sh >/dev/null 2>&1; done;

start_test "Performance of managed test"
time for (( i=0; i<NUM_RUNS; i++)); do "$TEST_SCRIPT_DIR"/test_managed.sh >/dev/null 2>&1; done;

start_test "Performance of tests runner"
tests=()
for (( i=0; i<NUM_RUNS; i++)); do tests+=("$TEST_SCRIPT_DIR"/test_managed_runner.sh); done
time "$TESTSH" "${tests[@]}" >/dev/null 2>&1

start_test "Performance of inline test with failures"
time for (( i=0; i<NUM_RUNS; i++)); do ! "$TEST_SCRIPT_DIR"/test_inline_failures.sh >/dev/null 2>&1; done;

start_test "Performance of managed test with failures"
time for (( i=0; i<NUM_RUNS; i++)); do ! "$TEST_SCRIPT_DIR"/test_managed_failures.sh >/dev/null 2>&1; done;

start_test "Performance of tests runner with failures"
tests=()
for (( i=0; i<NUM_RUNS; i++)); do tests+=("$TEST_SCRIPT_DIR"/test_managed_failures_runner.sh); done
time ! "$TESTSH" "${tests[@]}" >/dev/null 2>&1
