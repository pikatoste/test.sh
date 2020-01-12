test_01_ok() {
  start_test "Assertions should not fail when the assertion succeeds"
  assert_true "true" "ok"
  assert_false "false" "nok"
}

test_02_fail() {
  start_test "assert_true should fail when the assertion is false"
  assert_true "true" "ok"
  assert_true "false" "nok"
}

test_03_fail() {
  start_test "assert_false shoud fail when the assertion is true"
  assert_false "true" "ok"
  assert_false "false" "nok"
}

source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/../test.sh

! subshell "FAIL_FAST= SUBSHELL=always run_tests" || false

start_test "Failed assertions should interrupt the test when FAIL_FAST is true"
! CURRENT_TEST_NAME= "$TEST_SCRIPT_DIR"/do_test_assert_nosubshell.sh || false
