source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/../test.sh

set_test_name "Inline test failures should display the failed test in the main output"
# run in a different test script let this test pass
! CURRENT_TEST_NAME= "$TEST_SCRIPT_DIR"/do_test_inline.sh

# TODO: check output
