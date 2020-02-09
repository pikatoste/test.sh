#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../../test.sh

teardown_test_suite() {
  assert_failure "[[ a = a ]]"
}

teardown_test() {
  assert_failure "[[ b = b ]]"
}

test_performance_managed_1() {
  start_test "Performance managed fail test"
  assert_success "[[ a = a ]]"
  assert_failure "[[ a = b ]]"
  assert_equals a a
  assert_equals a b
}

run_tests
