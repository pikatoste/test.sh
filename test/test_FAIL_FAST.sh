#!/bin/bash

source "$(dirname "$(readlink -f "$0")")"/../test.sh

test_ok() {
  touch "$TEST_TMP"/.test_ok
  true
}

test_fail() {
  touch "$TEST_TMP"/.test_fail
  false
  true
}

start_test "Any command that fails in the body of a test function should make the test to fail"
rm -f "$TEST_TMPR"/.test_ok "$TEST_TMP"/.test_fail
TRY&&(:
  CURRENT_TEST_NAME= run_tests "test_fail" 3>&1 )
CATCH nonzero && print_exception
ENDTRY
[[ $TRY_EXIT_CODE != 0 ]]
[ -f "$TEST_TMP"/.test_fail ]

start_test "When FAIL_FAST is true the first test failure should interrupt the script"
rm -f "$TEST_TMP"/.test_ok "$TEST_TMP"/.test_fail
TRY&&(:
  FAIL_FAST=1 CURRENT_TEST_NAME= run_tests "test_fail" "test_ok" 3>&1 )
CATCH nonzero && print_exception
ENDTRY
[[ $TRY_EXIT_CODE != 0 ]]
[ ! -f "$TEST_TMP"/.test_ok ]
[   -f "$TEST_TMP"/.test_fail ]

start_test "When FAIL_FAST is false failures should not interrupt the script but signal failure at the end"
rm -f "$TEST_TMP"/.test_ok "$TEST_TMP"/.test_fail
TRY&&(:
  FAIL_FAST= CURRENT_TEST_NAME= run_tests "test_fail" "test_ok" 3>&1 )
CATCH nonzero && print_exception
ENDTRY
[[ $TRY_EXIT_CODE != 0 ]]
[ -f "$TEST_TMP"/.test_ok ]
[ -f "$TEST_TMP"/.test_fail ]
