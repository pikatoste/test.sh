#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../../test.sh

test_performance_managed_1() {
  start_test "Performance managed test 1"
  assert_success "[[ a = a ]]"
  assert_failure "[[ a = b ]]"
  assert_equals a a
}

run_tests
