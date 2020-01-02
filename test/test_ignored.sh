TEST_SCRIPT="$(readlink -f "$0")"
TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
source "$TEST_SCRIPT_DIR"/../test.sh

test_01() {
  set_test_name "test_01"
  false
}

test_02() {
  set_test_name "test_02"
  true
}

! subshell "FAIL_FAST=1 run_tests"

