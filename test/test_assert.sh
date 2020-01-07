test_01_ok() {
  set_test_name "Assertions should not fail when the assertion succeeds"
  assert_true "true" "ok"
  assert_false "false" "nok"
}

test_02_fail() {
  set_test_name "assert_true should fail when the assertion is false"
  assert_true "true" "ok"
  assert_true "false" "nok"
}

test_03_fail() {
  set_test_name "assert_false shoud fail when the assertion is true"
  assert_false "true" "ok"
  assert_false "false" "nok"
}

[ "$REENTRANT" != 1 ] || return 0
TEST_SCRIPT=${TEST_SCRIPT:-"$(readlink -f "$0")"}
TEST_SCRIPT_DIR=${TEST_SCRIPT_DIR:-$(dirname "$TEST_SCRIPT")}
source "$TEST_SCRIPT_DIR"/../test.sh #|| return 0 #"$1"

! subshell "FAIL_FAST=0 run_tests"
