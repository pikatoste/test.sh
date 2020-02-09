#!/bin/bash
TMPDIR=$TEST_TMPDIR
source "$(dirname "$(readlink -f "$0")")"/../test.sh

start_test "#74: Use TMPDIR for temporary files"
create_exception "fake" "fake"
TMPFILE_COUNT=$(find "$TMPDIR" -type f -o -type p | wc -l)
rm -f "$EXCEPTIONS_FILE"
assert_equals $1 "$TMPFILE_COUNT" "Wrong count of temporary files in $TMPDIR"
