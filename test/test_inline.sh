TEST_SCRIPT="$(readlink -f "$0")"
TEST_SCRIPT_DIR=$(dirname "$TEST_SCRIPT")
source "$TEST_SCRIPT_DIR"/../test.sh

set_test_name "Inline test fails should reflect the failed test in the output"
# run in a different test script let this test pass
! CURRENT_TEST_NAME= "$TEST_SCRIPT_DIR"/do_test_inline.sh

# TODO: check output
