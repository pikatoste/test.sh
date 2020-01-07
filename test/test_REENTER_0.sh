TEST_SCRIPT="$(readlink -f "$0")"
TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
source "$TEST_SCRIPT_DIR"/../test.sh

test_01() {
  true
}

set_test_name "Test config REENTER=0"
CURRENT_TEST_NAME= REENTER=0 run_tests
