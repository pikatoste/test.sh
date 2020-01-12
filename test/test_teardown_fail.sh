teardown_test_suite() {
  false
}

teardown_test() {
  false
}

test_01() {
  true
}

source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/../test.sh

start_test "Failing teardown functions should not break the test"
# run in a different test script to avoid the race condition on the log output
CURRENT_TEST_NAME= run_tests

# TODO: check output
