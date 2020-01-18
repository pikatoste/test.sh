#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

OUT=$TEST_SCRIPT_DIR/.test_setup_error.sh.out
FILES_DIR=$TEST_SCRIPT_DIR/files

start_test "When setup_test_suite fails, an error message should be displayed in the main output"
! INLINE=     run_test_script "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh [setup_test_suite] >"$OUT" 2>&1 || false
diff "$FILES_DIR"/test_setup_error.1.out "$OUT"
rm -f "$OUT"
! INLINE=true run_test_script "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh [setup_test_suite] >"$OUT" 2>&1 || false
diff "$FILES_DIR"/test_setup_error.1.out "$OUT"
rm -f "$OUT"

start_test "When setup_test fails a failed test error message should be displayed in the main output"
! INLINE=     run_test_script "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh [setup_test] >"$OUT" 2>&1 || false
diff "$FILES_DIR"/test_setup_error.2.out "$OUT"
rm -f "$OUT"
! INLINE=true run_test_script "$TEST_SCRIPT_DIR"/do_test_error_reporting.sh [setup_test] >"$OUT" 2>&1 || false
diff "$FILES_DIR"/test_setup_error.3.out "$OUT"
rm -f "$OUT"
