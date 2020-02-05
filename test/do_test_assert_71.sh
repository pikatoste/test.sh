#!/bin/bash

STACK_TRACE=no
source "$(dirname "$(readlink -f "$0")")"/../test.sh

test_01() {
  assert_true false "test_01"
}

teardown_test() {
  assert_true false "teardown_test"
}

teardown_test_suite() {
  assert_true false "teardown_test_suite"
}

result_of 'assert_true false "first"'
result_of 'assert_true false "second"'

run_tests
