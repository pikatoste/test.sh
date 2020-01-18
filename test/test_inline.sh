#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

OUTFILE="$TEST_SCRIPT_DIR"/.test_inline.out

start_test "Inline test failures should display the failed test in the main output"
OUT="$TEST_SCRIPT_DIR"/.do_test_inline.sh.main.out
( ! COLOR=no run_test_script "$TEST_SCRIPT_DIR"/do_test_inline.sh >"$OUT" 2>&1 || false )
diff - "$OUT" <<EOF
* do_test_inline ok
* do_test_inline fail
EOF
rm "$OUT"
rm "$OUTFILE"

start_test "Inline tests should invoke setup and teardown functions"
! run_test_script "$TEST_SCRIPT_DIR"/do_test_inline.sh || false
diff - "$OUTFILE" <<EOF
setup_test_suite
setup_test
teardown_test
setup_test
teardown_test
teardown_test_suite
EOF
rm "$OUTFILE"
