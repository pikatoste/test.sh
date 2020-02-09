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

try: assert_true false "first"
catch: print_exception
endtry
try: assert_true false "second"
catch: print_exception
endtry

run_tests
