#!/bin/bash
STACK_TRACE=no
PRUNE_PATH='*/'
source "$(dirname "$(readlink -f "$0")")"/../test.sh

func1() {
  [[ $FAIL_FUNC != *\[$FUNCNAME\]* ]] || false
  func2
}

func2() {
  [[ $FAIL_FUNC != *\[$FUNCNAME\]* ]] || false
  func_assert
}

@test:
@body: {
  [[ $FAIL_FUNC != *\[$FUNCNAME\]* ]] || false
  func1
}

@teardown: {
  [[ $FAIL_FUNC != *\[$FUNCNAME\]* ]] || false
  true
}

@teardown_once: {
  [[ $FAIL_FUNC != *\[$FUNCNAME\]* ]] || false
  true
}

func_assert() {
  [[ $FAIL_FUNC != *\[$FUNCNAME\]* ]] || assert_success false
  true
}

@setup: {
  [[ $FAIL_FUNC != *\[$FUNCNAME\]* ]] || false
  true
}

@setup_once: {
  [[ $FAIL_FUNC != *\[$FUNCNAME\]* ]] || false
  true
}

FAIL_FUNC=$1

if [[ $INLINE ]]; then
  start_test "do_test_error_reporting inline"
  test_01
  start_test "do_test_error_reporting inline maybe not reached"
else
  @run_tests
fi
