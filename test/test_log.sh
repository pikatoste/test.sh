#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "The log file should contain test stdout and stderr"
# run in a different test script to avoid the race condition on the log output
! run_test_script do_test_log.sh || false
OUT=$LOG_DIR/do_test_log.sh.out
grep ^output$ "$OUT"
grep ^stderr$ "$OUT"

start_test "Start test events should be logged"
grep "Start test: passing test" "$OUT"
grep "Start test: failing test" "$OUT"

start_test "Test passed events should be logged"
grep "PASSED: passing test" "$OUT"

start_test "Test failed events should be logged"
grep "FAILED: failing test" "$OUT"
