TEST_SCRIPT="$(readlink -f "$0")"
TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
source "$TEST_SCRIPT_DIR"/../test.sh

test_01_ok() {
  display_test_name "Assertions should not fail when the assertion succeeds"
  assert_true "true" "ok"
  assert_false "false" "nok"
}

test_02_fail() {
  display_test_name "assert_true shoud fail when the assertion is false"
  assert_false "true" "ok"
  assert_false "false" "nok"
}

test_03_fail() {
  display_test_name "assert_false should fail when the assertion is true"
  assert_true "true" "ok"
  assert_true "false" "nok"
}

! subshell "FAIL_FAST=0 run_tests"
