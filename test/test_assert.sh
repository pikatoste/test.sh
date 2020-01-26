#!/bin/bash
fail_validation() {
  false
  true
}

source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "Assertions should not fail when the assertion succeeds"
( assert_true "true" )
( assert_false "false" )
( assert_false "subshell fail_validation" )
( assert_equals a a )

start_test "assert_true should fail when the assertion is false"
( ! subshell "assert_true \"false\" ok" || false )

start_test "assert_false shoud fail when the assertion is true"
( ! subshell "assert_false \"true\" nok" || false )

start_test "assert_equals shoud fail when the arguments are not equal"
( ! subshell "assert_equals expected current wrong" || false )

start_test "Failed assertions should interrupt the test when FAIL_FAST is true"
( ! run_test_script do_test_assert_nosubshell.sh || false )
