#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../../test.sh

teardown_test_suite() {
  assert_false "[[ a = a ]]"
}

teardown_test() {
  assert_false "[[ b = b ]]"
}

test_performance_managed_1() {
  start_test "Performance managed fail test"
  assert_true "[[ a = a ]]"
  assert_false "[[ a = b ]]"
  assert_equals a a
  assert_equals a b
}

run_tests
