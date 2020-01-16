fail_validation() {
  false
  true
}

# TODO: check with different values of SUBSHELL
source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/../test.sh

start_test "Assertions should not fail when the assertion succeeds"
assert_true "true" "ok"
assert_false "false" "nok"
assert_false "subshell fail_validation" "nok"

start_test "assert_true should fail when the assertion is false"
! subshell "assert_true \"false\"" || false

start_test "assert_false shoud fail when the assertion is true"
! subshell "assert_false \"true\"" || false

# TODO: check for FAIL_FAST, does not belong here
start_test "Failed assertions should interrupt the test when FAIL_FAST is true"
! CURRENT_TEST_NAME= "$TEST_SCRIPT_DIR"/do_test_assert_nosubshell.sh || false
