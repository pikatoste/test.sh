#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "Teardown functions should be called"
run_test_script do_test_teardown.sh
OUTFILE="$LOG_DIR"/do_test_teardown.sh.out
OUTFILE2="$TEST_SCRIPT_DIR"/.do_test_teardown.out
grep -v '\[test\.sh\]' "$OUTFILE" >"$OUTFILE2"
diff - "$OUTFILE2" <<EOF
test_01
teardown_test
teardown_test_suite
EOF
rm "$OUTFILE2"

start_test "A failure in teardown_test should not terminate the test with failure"
run_test_script do_test_teardown.sh teardown_test
OUTFILE="$LOG_DIR"/do_test_teardown.sh.out
OUTFILE2="$TEST_SCRIPT_DIR"/.do_test_teardown.out
grep -v '\[test\.sh\]' "$OUTFILE" >"$OUTFILE2"
diff - "$OUTFILE2" <<EOF
test_01
teardown_test
teardown_test_suite
EOF
rm "$OUTFILE2"

start_test "A failure in teardown_test_suite should terminate the test with failure"
run_test_script do_test_teardown.sh teardown_test_suite
OUTFILE="$LOG_DIR"/do_test_teardown.sh.out
OUTFILE2="$TEST_SCRIPT_DIR"/.do_test_teardown.out
grep -v '\[test\.sh\]' "$OUTFILE" >"$OUTFILE2"
diff - "$OUTFILE2" <<EOF
test_01
teardown_test
teardown_test_suite
EOF
rm "$OUTFILE2"
