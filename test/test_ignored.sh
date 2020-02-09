#!/bin/bash
source "$(dirname "$(readlink -f "$0")")"/../test.sh

FILES_DIR=$TEST_SCRIPT_DIR/files

start_test "In managed mode and FAIL_FAST true when a test fails the remaining tests should be displayed as skipped in the main output"
OUT=$TEST_SCRIPT_DIR/.test_script.out
! FAIL_FAST=1 run_test_script do_test_ignored.sh >"$OUT" || false
diff "$FILES_DIR"/test_ignored.out "$OUT"
rm -f "$OUT"
