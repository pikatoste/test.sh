#!/bin/bash

STACK_TRACE=no
source "$(dirname "$(readlink -f "$0")")"/../test.sh

@test:
@body: {
  assert_success false "test_01"
}

@teardown: {
  assert_success false "teardown_test"
}

@teardown_once: {
  assert_success false "teardown_test_suite"
}

try: assert_success false "first"
catch: print_exception
endtry

try: assert_success false "second"
catch: print_exception
endtry

@run_tests
