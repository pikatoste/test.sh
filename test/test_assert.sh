#!/bin/bash
INCLUDE_GLOB="include/*.sh"
source "$(dirname "$(readlink -f "$0")")"/../test.sh

fail_validation() {
  false
  true
}

start_test "Assertions should not fail when the assertion succeeds"
  assert_success "true"
  assert_failure "false"
  assert_failure "fail_validation"
  assert_equals a a

start_test "assert_success should fail when the assertion is false"
  try: assert_success false "ok"
  catch nonzero: print_exception
  endtry
  failed

start_test "assert_failure should fail when the assertion is true"
  try: assert_failure true "nok"
  catch nonzero: print_exception
  endtry
  failed

start_test "assert_equals should fail when the arguments are not equal"
  try: assert_equals 'expected' 'current' 'wrong'
  catch nonzero: print_exception
  endtry
  failed

start_test "Failed assertions should interrupt the test when FAIL_FAST is true"
  try: run_test_script do_test_assert_nosubshell.sh
  catch nonzero: print_exception
  endtry
  failed

ffail() {
  false
  echo "What?!" >"$OUT"
}
start_test "#89: assert_failure should execute the expression in errexit context"
  OUT="$TEST_SCRIPT_DIR"/.test_assert.out
  rm -f "$OUT"
  assert_failure ffail
  assert_failure "[[ -f \"$OUT\" ]]" "The file should not have been created"
  rm -f "$OUT"

start_test "#98: non-zero exit code in the expression of assert_failure prints the failure but does not print an assertion failure"
  generate_test_success_check 'assert_failure "[[ a = b ]]"' <<EOF
[test.sh] Expected failure:
[test.sh] Error in _eval(test.sh:): '[[ a = b ]]' exited with status 1
[test.sh]  at assert_failure(test.sh:)
[test.sh]  at main(the_test.sh:)
EOF
