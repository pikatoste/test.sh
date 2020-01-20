#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

FILES_DIR=$TEST_SCRIPT_DIR/files

start_test "In managed mode and SUBSHELL=always when a test fails the remaining tests should be displayed as skipped in the main output"
OUT=$TEST_SCRIPT_DIR/.test_script.out
! FAIL_FAST=1 SUBSHELL=always run_test_script "$TEST_SCRIPT_DIR"/do_test_ignored.sh >"$OUT" || false
diff "$FILES_DIR"/test_ignored.out "$OUT"
rm -f "$OUT"
