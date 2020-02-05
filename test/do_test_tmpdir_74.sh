#!/bin/bash
TMPDIR=$TEST_TMPDIR
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "#74: Use TMPDIR for temporary files"
save_stack
TMPFILE_COUNT=$(find "$TMPDIR" -type f -o -type p | wc -l)
rm -f "$EXCEPTION"
assert_equals 2 "$TMPFILE_COUNT" "Expected two temporary files in $TMPDIR"
