TEST_SCRIPT="$(readlink -f "$0")"
TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
source "$TEST_SCRIPT_DIR"/../test.sh

set_test_name "do_test_inline fail"
false
