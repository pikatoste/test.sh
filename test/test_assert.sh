#!/bin/bash
fail_validation() {
  false
  true
}

source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "Assertions should not fail when the assertion succeeds"
( SUBSHELL=always assert_true "true" )
( SUBSHELL=always assert_false "false" )
( SUBSHELL=always assert_false "subshell fail_validation" )
( SUBSHELL=always assert_equals a a )
( SUBSHELL=never assert_true "true" )
( SUBSHELL=never assert_false "false" )
( SUBSHELL=never assert_false "subshell fail_validation" )
( SUBSHELL=never assert_equals a a )

start_test "assert_true should fail when the assertion is false"
( ! REENTER=1 subshell "assert_true \"false\" ok" || false )
( ! REENTER=  subshell "assert_true \"false\" ok" || false )

start_test "assert_false shoud fail when the assertion is true"
( ! REENTER=1 subshell "assert_false \"true\" nok" || false )
( ! REENTER=  subshell "assert_false \"true\" nok" || false )

start_test "assert_equals shoud fail when the arguments are not equal"
( ! REENTER=1 subshell "assert_equals expected current wrong" || false )
( ! REENTER=  subshell "assert_equals expected current wrong" || false )

start_test "Failed assertions should interrupt the test when FAIL_FAST is true"
( ! REENTER=1 run_test_script do_test_assert_nosubshell.sh || false )
