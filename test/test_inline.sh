source "$(dirname "$(readlink -f "$BASH_SOURCE")")"/../test.sh

OUTFILE="$TEST_SCRIPT_DIR"/.test_inline.out

start_test "Inline test failures should display the failed test in the main output"
# run in a different test script let this test pass
! CURRENT_TEST_NAME= "$TEST_SCRIPT_DIR"/do_test_inline.sh || false

# TODO: check output

start_test "Inline tests should invoke setup and teardown functions"
! CURRENT_TEST_NAME= "$TEST_SCRIPT_DIR"/do_test_inline.sh || false
