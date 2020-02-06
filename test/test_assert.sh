#!/bin/bash
INCLUDE_GLOB="include/*.sh"
source "$(dirname "$(readlink -f "$0")")"/../test.sh

fail_validation() {
  false
  true
}

start_test "Assertions should not fail when the assertion succeeds"
( assert_true "true" )
( assert_false "false" )
( assert_false "fail_validation" )
( assert_equals a a )

start_test "assert_true should fail when the assertion is false"
try_catch_print "assert_true \"false\" ok"
[[ $TRY_EXIT_CODE != 0 ]]

start_test "assert_false shoud fail when the assertion is true"
try_catch_print "assert_false \"true\" nok"
[[ $TRY_EXIT_CODE != 0 ]]

start_test "assert_equals shoud fail when the arguments are not equal"
try_catch_print "assert_equals expected current wrong"
[[ $TRY_EXIT_CODE != 0 ]]

start_test "Failed assertions should interrupt the test when FAIL_FAST is true"
try_catch_print "run_test_script do_test_assert_nosubshell.sh"
[[ $TRY_EXIT_CODE != 0 ]]

ffail() {
  false
  echo "What?!" >"$OUT"
}
start_test "#89: assert_false should execute the expression in errexit context"
OUT="$TEST_SCRIPT_DIR"/.test_assert.out
rm -f "$OUT"
assert_false ffail
assert_false "[[ -f \"$OUT\" ]]" "The file should not have been created"
rm -f "$OUT"

start_test "#98: non-zero exit code in the expression of assert_false does not print an assertion failure nor an error report"
generate_test_success_check 'assert_false "[[ a = b ]]"' <<EOF
EOF
