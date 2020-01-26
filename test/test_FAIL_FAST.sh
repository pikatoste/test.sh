#!/bin/bash

source "$(dirname "$(readlink -f "$0")")"/../test.sh

test_ok() {
  touch "$TEST_SCRIPT_DIR"/.test_ok
  TEST_OK=1
  true
}

test_fail() {
  touch "$TEST_SCRIPT_DIR"/.test_fail
  TEST_FAIL=1
  false
  true
}

# TODO: test with both values of FAIL_FAST
start_test "Any command that fails in the body of a test function should make the test to fail"
rm -f "$TEST_SCRIPT_DIR"/.test_ok "$TEST_SCRIPT_DIR"/.test_fail
! CURRENT_TEST_NAME= run_tests test_fail 3>&1 || false
[ -f "$TEST_SCRIPT_DIR"/.test_fail ]

start_test "When FAIL_FAST is true the first test failure should interrupt the script"
rm -f "$TEST_SCRIPT_DIR"/.test_ok "$TEST_SCRIPT_DIR"/.test_fail
! FAIL_FAST=1 CURRENT_TEST_NAME= run_tests test_fail test_ok 3>&1 || false
! [ -f "$TEST_SCRIPT_DIR"/.test_ok ] || false
[ -f "$TEST_SCRIPT_DIR"/.test_fail ]

start_test "When FAIL_FAST is false failures should not interrupt the script but signal failure at the end"
rm -f "$TEST_SCRIPT_DIR"/.test_ok "$TEST_SCRIPT_DIR"/.test_fail
! FAIL_FAST= CURRENT_TEST_NAME= run_tests test_fail test_ok 3>&1 || false
[ -f "$TEST_SCRIPT_DIR"/.test_ok ]
[ -f "$TEST_SCRIPT_DIR"/.test_fail ]
