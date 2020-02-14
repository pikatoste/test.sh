#!/bin/bash

source "$(dirname "$(readlink -f "$0")")"/../test.sh

@test: "test_fail"
@body: {
  touch "$TEST_TMP"/.test_fail
  false
  true
}

@test: "test_ok"
@body: {
  touch "$TEST_TMP"/.test_ok
  true
}

# start_test "Any command that fails in the body of a test function should make the test to fail"
# try:
#   @run_tests 3>&1
# catch nonzero: print_exception
# endtry
# failed
# [ -f "$TEST_TMP"/.test_fail ]

start_test "When FAIL_FAST is true the first test failure should interrupt the script"
rm -f "$TEST_TMP"/.test_fail "$TEST_TMP"/.test_ok
assert_failure 'FAIL_FAST=1 @run_tests 3>&1' "run_tests exited successfully"
[   -f "$TEST_TMP"/.test_fail ]
[ ! -f "$TEST_TMP"/.test_ok ]

start_test "When FAIL_FAST is false failures should not interrupt the script but signal failure at the end"
rm -f "$TEST_TMP"/.test_fail "$TEST_TMP"/.test_ok
assert_failure 'FAIL_FAST= @run_tests 3>&1' "run_tests exited successfully"
[ -f "$TEST_TMP"/.test_fail ]
[ -f "$TEST_TMP"/.test_ok ]
