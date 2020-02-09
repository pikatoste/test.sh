#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../../test.sh

teardown_test_suite() {
  assert_failure "[[ a = a ]]"
}

teardown_test() {
  assert_failure "[[ b = b ]]"
}

start_test "Performance inline fail test"
assert_success "[[ a = a ]]"
assert_failure "[[ a = b ]]"
assert_equals a a
assert_equals a b
