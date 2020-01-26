#!/bin/bash

FAIL_FAST=1
source "$(dirname "$(readlink -f "$0")")"/../test.sh

test_01_ok() {
  start_test "Assertions should not fail when the assertion succeeds"
  assert_true "true" "ok"
  assert_false "false" "nok"
}

test_02_fail() {
  start_test "assert_true should fail when the assertion is false"
  assert_true "true" "ok"
  assert_true "false" "nok"
}

test_03_fail() {
  start_test "assert_false shoud fail when the assertion is true"
  assert_false "true" "ok"
  assert_false "false" "nok"
}

run_tests
