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

TRY&&(block; assert_true false "first" )
CATCH nonzero && print_exception
ENDTRY
TRY&&(block; assert_true false "second" )
CATCH nonzero && print_exception
ENDTRY

run_tests
