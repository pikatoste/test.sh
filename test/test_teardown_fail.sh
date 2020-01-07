teardown_test_suite() {
  false
}

teardown_test() {
  false
}

test_01() {
  true
}

[ "$REENTRANT" != 1 ] || return 0
TEST_SCRIPT="$(readlink -f "$0")"
TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
source "$TEST_SCRIPT_DIR"/../test.sh

set_test_name "Failing teardown functions should not break the test"
# run in a different test script to avoid the race condition on the log output
CURRENT_TEST_NAME= run_tests

# TODO: check output
