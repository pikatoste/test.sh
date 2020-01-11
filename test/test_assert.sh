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

source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/../test.sh

! subshell "FAIL_FAST=0 run_tests"
