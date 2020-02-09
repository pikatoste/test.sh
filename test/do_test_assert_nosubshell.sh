#!/bin/bash

FAIL_FAST=1
source "$(dirname "$(readlink -f "$0")")"/../test.sh

test_01_ok() {
  start_test "Assertions should not fail when the assertion succeeds"
  assert_success "true" "ok"
  assert_failure "false" "nok"
}

test_02_fail() {
  start_test "assert_success should fail when the assertion is false"
  assert_success "true" "ok"
  assert_success "false" "nok"
}

test_03_fail() {
  start_test "assert_failure should fail when the assertion is true"
  assert_failure "true" "ok"
  assert_failure "false" "nok"
}

run_tests
